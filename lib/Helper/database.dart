import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supalist/Models/item.dart';
import 'package:supalist/Models/supalist.dart';
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
      version: 1,
      onCreate: _onCreate,
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
        checked INTEGER,
        
        listId INTEGER,
        FOREIGN KEY (listId) REFERENCES lists (id)
      )
    ''');
  }

  delete() async {
    await lock.synchronized(() async {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'supalist.db');
      await deleteDatabase(path);
      _database = null;
    });
  }

  add(Supalist itemlist) async {
    await lock.synchronized(() async {
      Database db = await instance.database;
      int listId = await db.insert('lists', itemlist.toMap());

      for (Item item in itemlist.items) {
        addItem(item, listId);
      }
    });
  }

  addItem(Item item, int listId) async {
    await lock.synchronized(() async {
      Database db = await instance.database;
      Map<String, dynamic> map = item.toMap();
      map.addAll({'listId': listId });
      await db.insert('items', map);
    });
  }

  update(Supalist itemlist) async {
    await lock.synchronized(() async {
      Database db = await instance.database;
      int failed = await db.update('lists', itemlist.toMap(), where: 'id = ?', whereArgs: [itemlist.id]);
      if (failed == 0) {
        add(itemlist);
        return;
      }
      for (Item item in itemlist.items) {
        updateItem(item);
      }
    });
  }

  updateItem(Item item) async {
    await lock.synchronized(() async {
      Database db = await instance.database;
      await db.update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
    });
  }

  remove(int id) async {
    await lock.synchronized(() async {
      Database db = await instance.database;
      await db.delete('items', where: 'listId = ?', whereArgs: [id]);
      await db.delete('lists', where: 'id = ?', whereArgs: [id]);
    });
  }

  removeItem(int id) async {
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