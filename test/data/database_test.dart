import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supalist/data/database.dart';
import 'package:supalist/models/item.dart';
import 'package:supalist/models/supalist.dart';

class _FakePathProvider extends PathProviderPlatform {
  final String path;
  _FakePathProvider(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  bool _sqliteAvailable = false;

  setUpAll(() async {
    // Try to initialize sqflite ffi for tests. If native sqlite isn't present,
    // mark tests to skip. We also attempt to open an in-memory db to force
    // loading the native sqlite library so we can detect availability.
    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      // Try opening an in-memory database to ensure native library loads.
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.close();
      _sqliteAvailable = true;
    } catch (_) {
      _sqliteAvailable = false;
    }
  });

  test('DatabaseHelper CRUD operations', () async {
    if (!_sqliteAvailable) {
      // Skip test on environments without native sqlite3 library
      return;
    }
    final tempDir = await Directory.systemTemp.createTemp('supalist_test');
    // Point path_provider to the temp directory
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);

    // Ensure any existing DB is removed
    await DatabaseHelper.instance.delete();

    // Create a list with two items
    final list = Supalist(name: 'Test List', owner: 'tester');
    list.items.add(Item(name: 'a', owner: 'tester', list: list.id));
    list.items.add(Item(name: 'b', owner: 'tester', list: list.id));

    await DatabaseHelper.instance.addList(list);
    final id = list.id;
    final all = await DatabaseHelper.instance.getLists();
    expect(all.any((e) => e.id == id), isTrue);

    final fetched = await DatabaseHelper.instance.getList(id);
    expect(fetched.items.length, 2);

    // Update
    fetched.name = 'Updated';
    await DatabaseHelper.instance.updateList(fetched);
    final fetched2 = await DatabaseHelper.instance.getList(id);
    expect(fetched2.name, 'Updated');

    // Remove one item
    final removeId = fetched2.items.first.id!;
    await DatabaseHelper.instance.removeItem(removeId);
    final afterRemove = await DatabaseHelper.instance.getList(id);
    expect(afterRemove.items.length, 1);

    // Remove list
    await DatabaseHelper.instance.remove(id);
    final afterDelete = await DatabaseHelper.instance.getLists();
    expect(afterDelete.any((e) => e.id == id), isFalse);

    await DatabaseHelper.instance.delete();
    await tempDir.delete(recursive: true);
  });
}
