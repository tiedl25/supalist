import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supalist/models/item.dart';
import 'package:supalist/models/supalist.dart';
import 'package:synchronized/synchronized.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  //Singleton Pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  static var lock = Lock(reentrant: true);

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'supalist.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE lists(
        id INTEGER PRIMARY KEY,
        name TEXT,
        owner INTEGER,
        image BLOB,
        timestamp TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY,
        name TEXT,
        timestamp TEXT,
        checked INTEGER DEFAULT 0,
        history INTEGER DEFAULT 0,
        
        listId INTEGER,
        FOREIGN KEY (listId) REFERENCES lists (id)
      )
    ''');
  }

  Future<void> delete() async {
    await lock.synchronized(() async {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'supalist.db');
      await deleteDatabase(path);
      _database = null;
    });
  }

  Future<int> add(Supalist itemlist) async {
    return await lock.synchronized(() async {
      Database db = await instance.database;
      int listId = await db.insert('lists', itemlist.toMap());

      for (Item item in itemlist.items) {
        addItem(item, listId);
      }
      return listId;
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await lock.synchronized(() async {
      if (oldVersion < 2) {
        // Add 'history' column to 'items' table
        await db.execute('ALTER TABLE items ADD COLUMN history BOOLEAN DEFAULT 0');
        // Migrate existing data if necessary
        var items = await db.query('items');
        for (var item in items) {
          await db.update(
            'items',
            {'history': 0},
            where: 'id = ?',
            whereArgs: [item['id']],
          );
        }
      }
    });
  }

  Future<int> addItem(Item item, int listId) async {
    return await lock.synchronized(() async {
      Database db = await instance.database;
      Map<String, dynamic> map = item.toMap();
      map.addAll({'listId': listId });
      return await db.insert('items', map);
    });
  }

  Future<void> update(Supalist itemlist) async {
    await lock.synchronized(() async {
      Database db = await instance.database;
      int failed = await db.update('lists', itemlist.toMap(), where: 'id = ?', whereArgs: [itemlist.id]);
      if (failed == 0) {
        await add(itemlist);
        return;
      }
      for (Item item in itemlist.items) {
        await updateItem(item);
      }
    });
  }

  Future<void> updateItem(Item item) async {
    await lock.synchronized(() async {
      Database db = await instance.database;
      await db.update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
    });
  }

  Future<void> remove(int id) async {
    await lock.synchronized(() async {
      Database db = await instance.database;
      await db.delete('items', where: 'listId = ?', whereArgs: [id]);
      await db.delete('lists', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> removeItem(int id) async {
    await lock.synchronized(() async {
      Database db = await instance.database;
      await db.delete('items', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future <List<Supalist>> getLists() async {
    List<Supalist> itemList = await lock.synchronized(() async {
      Database db = await instance.database;
      var items = await db.query('lists', orderBy: 'id');
      List<Supalist> itemList = items.isNotEmpty ? items.map((e) => Supalist.fromMap(e)).toList() : [];

      return itemList;      
    });
    return itemList;
  }

  Future<Supalist> getList(int id) async {
    Database db = await instance.database;
    Supalist itemlist = await lock.synchronized(() async {
      var response = await db.query('lists', orderBy: 'id', where: 'id = ?', whereArgs: [id]);
      Supalist itemlist = (response.isNotEmpty ? (response.map((e) => Supalist.fromMap(e)).toList()) : [])[0];

      itemlist.items = await getItems(id, db);
      return itemlist;
    });
    return itemlist;
  }

  Future<List<Item>> getItems(int id, [Database? db]) async {
    db = db ?? await instance.database;
    var items = await db.query('items', where: 'listId = ?', whereArgs: [id]);
    List<Item> itemlist = items.isNotEmpty ? items.map((e) => Item.fromMap(e)).toList() : [];
    return itemlist;
  }
}