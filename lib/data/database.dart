import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supalist/data/supabase.dart';
import 'package:supalist/models/item.dart';
import 'package:supalist/models/schema.dart';
import 'package:supalist/models/supalist.dart';
import 'package:supalist/data/backend_connector.dart';

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

  Future<PowerSyncDatabase> _initDatabase() async {
    final path = await getDatabasePath();

    final db = PowerSyncDatabase(schema: loggedIn ? schema : localSchema, path: path);
    await db.initialize();
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
        final connector = BackendConnector(db);
        await db.connect(connector: connector);

        await uploadAllData(items: items, lists: lists);
      } else if (event == AuthChangeEvent.signedOut) {
        // Implicit sign out - disconnect, but don't delete data
        await db.disconnect();
        await db.updateSchema(localSchema);
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        // Supabase token refreshed - trigger token refresh for PowerSync.
        final connector = BackendConnector(db);
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

  Future<void> addList(Supalist itemlist) async {
    PowerSyncDatabase db = await instance.database;
    await db.execute('INSERT INTO lists (id, name, owner, timestamp) VALUES (?, ?, ?, ?)', itemlist.toMap().values.toList());

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