import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
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

  Future<PowerSyncDatabase> _initDatabase() async {
    final dir = await getApplicationSupportDirectory();
    final path = join(dir.path, _databaseName);

    final db = PowerSyncDatabase(schema: schema, path: path);
    await db.initialize();
    final connector = BackendConnector(db);

    await db.connect(connector: connector);
    return db;
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

    supalist.items = await getItems(id, db);
    return supalist;
  }

  Future<List<Item>> getItems(String id, [PowerSyncDatabase? db]) async {
    db = db ?? await instance.database;
    final rows = await db.getAll('SELECT * FROM items WHERE list = ?', [id]);
    List<Item> itemlist = rows.isNotEmpty ? rows.map((e) => Item.fromMap(e)).toList() : [];
    return itemlist;
  }
}