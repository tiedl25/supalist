import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supalist/data/result.dart';
import 'package:supalist/data/supabase.dart';
import 'package:supalist/models/access_rights.dart';
import 'package:supalist/models/item.dart';
import 'package:supalist/models/schema.dart';
import 'package:supalist/models/supalist.dart';
import 'package:supalist/data/backend_connector.dart';
import 'package:supalist/resources/strings.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static final String _databaseName = "powersync.db";
  static final int _databaseVersion = 1;

  static PowerSyncDatabase? _database;
  Future<PowerSyncDatabase> get database async => _database ??= await _initDatabase();

  Future<String> getDatabasePath() async {
    if (kIsWeb) {
      return _databaseName;
    }
    final dir = await getApplicationSupportDirectory();
    return join(dir.path, _databaseName);
  }

  Future<void> connectToDatabase(PowerSyncDatabase db) async {
    final connector = BackendConnector();
    await db.connect(connector: connector);
    return;
  }

  Future<PowerSyncDatabase> _initDatabase() async {
    final path = await getDatabasePath();

    final db = PowerSyncDatabase(schema: loggedIn ? schema : localSchema, path: path);
    await db.initialize();
    if (loggedIn) await connectToDatabase(db); //TODO: Move to auth listener
    listenForAuthenticationChanges();
    return db;
  }

  void listenForAuthenticationChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      PowerSyncDatabase db = await instance.database;

      if (event == AuthChangeEvent.signedIn) {
        List<Item> items = await getItems();
        List<Supalist> lists = await getLists();

        await db.updateSchema(schema);

        // Connect to PowerSync when the user is signed in
        final connector = BackendConnector();
        await db.connect(connector: connector);

        await uploadAllData(items: items, lists: lists);
      } else if (event == AuthChangeEvent.signedOut) {
        // Implicit sign out - disconnect, but don't delete data
        await db.disconnect();
        await db.updateSchema(localSchema);
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        // Supabase token refreshed - trigger token refresh for PowerSync.
        final connector = BackendConnector();
        await connector.prefetchCredentials();
      }
    });
  }

  Future<void> uploadAllData({List<Item> items = const [], List<Supalist> lists = const []}) async {
    PowerSyncDatabase db = await instance.database;

    items.forEach((item) => item.owner = userId);
    lists.forEach((list) => list.owner = userId);

    final sql = [
      'INSERT INTO lists (id, name, owner, timestamp) VALUES (?, ?, ?, ?)',
      'INSERT INTO items (id, name, timestamp, checked, history, owner, list) VALUES (?, ?, ?, ?, ?, ?, ?)',
    ];

    final parameterSets = [
      lists.map((list) => list.toMap().values.toList()).toList(),
      items.map((item) => item.toMap().values.toList()).toList(),
    ];

    await db.executeBatch(sql[0], parameterSets[0]);
    await db.executeBatch(sql[1], parameterSets[1]);
  }

  Future<void> logout() async {
    PowerSyncDatabase db = await instance.database;
    await Supabase.instance.client.auth.signOut();
    await db.disconnectAndClear();
  }

  Future<void> delete() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    _database = null;
  }

  Future<Result> addSharePermission(AccessRights permission) async {
    //TODO: Ensure permission is uploaded by the time the user tries to use the link
    PowerSyncDatabase db = await instance.database;

    if (currentUser == null) {
      return Result.failure(Strings.notAuthorized);
    }

    if (permission.userEmail == currentUser!.email) {
      return Result.failure(Strings.cannotShareWithYourself);
    }
    final permissionRowsWithListId = await db.getAll('SELECT * FROM accessRights WHERE list = ? and (user != ? or user is null)', [permission.list, userId]);
    List<AccessRights> permissionsWithListId = permissionRowsWithListId.map<AccessRights>((e) => AccessRights.fromMap(e)).toList();

    if (permissionsWithListId.any((p) => p.userEmail == permission.userEmail)) {
      AccessRights permissionWithSameUser = permissionsWithListId.firstWhere((p) => p.userEmail == permission.userEmail);

      if (permission.userEmail == null) {
        if (permission.expirationDate != permissionWithSameUser.expirationDate) {
          await db.execute(
            'UPDATE accessRights SET expirationDate = ? WHERE id = ?',
            [permission.expirationDate.toString(), permissionWithSameUser.id],
          );
        }
        return Result.success(permissionWithSameUser);
      } else {
        if (permissionWithSameUser.user != null) {
          return Result.failure(Strings.alreadyHasAccess);
        }

        if (permission.expirationDate != permissionWithSameUser.expirationDate) {
          await db.execute(
            'UPDATE accessRights SET expirationDate = ? WHERE id = ?',
            [permission.expirationDate.toString(), permissionWithSameUser.id],
          );
        }
        return Result.success(permissionWithSameUser);
      }
    }

    if (permissionsWithListId.any((p) => p.userEmail == null && permission.userEmail != null)) {
      AccessRights permissionWithoutUser = permissionsWithListId.firstWhere((p) => p.userEmail == null);

      if (permission.expirationDate != permissionWithoutUser.expirationDate) {
        await db.execute(
          'UPDATE accessRights SET expirationDate = ? WHERE id = ?',
          [permission.expirationDate.toString(), permissionWithoutUser.id],
        );
      }
      return Result.success(permissionWithoutUser);
    }


    if (permissionsWithListId.any((p) => p.userEmail != null && permission.userEmail == null && p.user == null)) {
      List<AccessRights> permissionsWithOtherUser = permissionsWithListId.where((p) => p.userEmail != null && p.user == null).toList();

      for (final (index, perm) in permissionsWithOtherUser.indexed) {
        if (index == 0) {
          if (permission.expirationDate != perm.expirationDate) {
            await db.execute(
              'UPDATE accessRights SET expirationDate = ?, userEmail = ? WHERE id = ?',
              [permission.expirationDate.toString(), null, perm.id],
            );
          } else {
            await db.execute(
              'UPDATE accessRights SET userEmail = ? WHERE id = ?',
              [null, perm.id],
            );
          }
        } else {
          await db.execute(
            'DELETE FROM accessRights WHERE id = ?',
            [perm.id],
          );
        }
      }
      return Result.success(permissionsWithOtherUser.first);
    }

    await db.execute(
      "INSERT INTO accessRights (id, list, user, userEmail, expirationDate) VALUES (?, ?, ?, ?, ?)",
      permission.toMap().values.toList(),
    );

    return Result.success(permission);
  }

  Future<Result> confirmPermission(String permissionId) async {
    PowerSyncDatabase db = await instance.database;

    final permissions = await db.get("SELECT * FROM accessRights WHERE id = ?", [permissionId]);

    if (permissions.isEmpty) return Result.failure(Strings.notAuthorized);
    
    AccessRights permission = AccessRights.fromMap(permissions);

    bool newPermission = false;

    if(permission.userEmail != null){
      if (permission.userEmail != currentUser!.email) return Result.failure(Strings.notAuthorized);

      permission.user = currentUser!.id;
      permission.expirationDate = null;
    } else {
      newPermission = true;
      permission = AccessRights(
        list: permission.list,
        user: currentUser!.id,
        userEmail: currentUser!.email,
      );
    }

    final existingPermissions = await db.getAll('SELECT * FROM accessRights WHERE list = ? AND user = ?', [permission.list, permission.user]);
    if (existingPermissions.isNotEmpty) return Result.failure(Strings.itemAlreadyAdded);    
    
    if (newPermission) {
      await db.execute(
        'INSERT INTO accessRights (id, list, user, userEmail, expirationDate) VALUES (?, ?, ?, ?, ?)',
        permission.toMap().values.toList(),
      );
    } else {
      await db.execute(
        'UPDATE accessRights SET user = ?, userEmail = ?, expirationDate = ? WHERE id = ?',
        [permission.user, permission.userEmail, permission.expirationDate.toString(), permission.id],
      );
    }
    return Result.success(null);
  }

  Future<Result> addPermission(AccessRights permission) async {
    PowerSyncDatabase db = await instance.database;
    await db.execute(
      'INSERT INTO accessRights (id, list, user, userEmail, expirationDate) VALUES (?, ?, ?, ?, ?)',
      permission.toMap().values.toList(),
    );
    return Result.success(null);
  }

  Future<void> addList(Supalist itemlist) async {
    PowerSyncDatabase db = await instance.database;

    await db.execute('INSERT INTO lists (id, name, owner, timestamp) VALUES (?, ?, ?, ?)', itemlist.toMap().values.toList());

    await addPermission(AccessRights(
      list: itemlist.id,
      user: itemlist.owner!,
      userEmail: currentUser!.email,
      expirationDate: null,
    ));    

    for (Item item in itemlist.items) {
      await addItem(item);
    }
  }

  Future<void> addItem(Item item) async {
    PowerSyncDatabase db = await instance.database;
    await db.execute('INSERT INTO items (id, name, timestamp, checked, history, owner, list) values (?, ?, ?, ?, ?, ?, ?)', item.toMap().values.toList());
  }

  Future<void> updateList(Supalist itemlist) async {
    PowerSyncDatabase db = await instance.database;
    await db.execute('UPDATE lists SET name = ?, owner = ?, timestamp = ? WHERE id = ?', [itemlist.name, itemlist.owner, itemlist.timestamp.toString(), itemlist.id]);
  }

  Future<void> updateItem(Item item) async {
    PowerSyncDatabase db = await instance.database;
    await db.execute('UPDATE items SET name = ?, timestamp = ?, checked = ?, history = ?, owner = ? WHERE id = ?', [item.name, item.timestamp.toString(), item.checked ? 1 : 0, item.history ? 1 : 0, item.owner, item.id]);
  }

  Future<void> remove(String id) async {
    PowerSyncDatabase db = await instance.database;
    await db.execute('DELETE FROM items WHERE list = ?', [id]);
    await db.execute('DELETE FROM lists WHERE id = ?', [id]);
  }

  Future<void> removeItem(String id) async {
    PowerSyncDatabase db = await instance.database;
    await db.execute('DELETE FROM items WHERE id = ?', [id]);
  }

  Future<void> leave(String id) async {
    PowerSyncDatabase db = await instance.database;
    await db.execute('DELETE FROM accessRights WHERE list = ? AND user = ?', [id, userId]);
  }

  Future <List<Supalist>> getLists() async {
    PowerSyncDatabase db = await instance.database;
    final rows = await db.getAll('SELECT * FROM lists');
    List<Supalist> lists = rows.isNotEmpty ? rows.map((e) => Supalist.fromMap(e)).toList() : [];

    return lists;
  }

  Future<Supalist> getList(String id) async {
    PowerSyncDatabase db = await instance.database;
    final row = await db.get('SELECT * FROM lists WHERE id = ?', [id]);
    Supalist supalist = Supalist.fromMap(row);

    supalist.items = await getItems(id: id, db: db);
    return supalist;
  }

  Future<List<Item>> getItems({String? id, PowerSyncDatabase? db}) async {
    db = db ?? await instance.database;
    final rows = await db.getAll('SELECT * FROM items WHERE ${id != null ? 'list = ?' : '1=1'}', id != null ? [id] : []);
    List<Item> itemlist = rows.isNotEmpty ? rows.map((e) => Item.fromMap(e)).toList() : [];
    return itemlist;
  }
}