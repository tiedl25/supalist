import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supalist/bloc/masterview_bloc.dart';
import 'package:supalist/bloc/masterview_states.dart';
import 'package:supalist/data/database.dart';

class _FakePathProvider extends PathProviderPlatform {
  final String path;
  _FakePathProvider(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  bool _sqliteAvailable = false;
  late Directory tempDir;

  setUpAll(() async {
    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      // create temp dir and set path provider
      tempDir = await Directory.systemTemp.createTemp('supalist_master_test');
      PathProviderPlatform.instance = _FakePathProvider(tempDir.path);

      // try opening an in-memory DB to ensure native lib is available
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.close();
      _sqliteAvailable = true;
    } catch (_) {
      _sqliteAvailable = false;
    }
  });

  tearDownAll(() async {
    if (_sqliteAvailable) {
      await DatabaseHelper.instance.delete();
    }
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  test('MasterViewCubit CRUD integration', () async {
    if (!_sqliteAvailable) return;

    // Ensure clean DB
    await DatabaseHelper.instance.delete();

    final cubit = MasterViewCubit();

    // wait for initial load
    await cubit.stream.firstWhere((s) => s is MasterViewLoaded);
    expect(cubit.state, isA<MasterViewLoaded>());

    // add
    await cubit.addSupalist('List A');
    final state1 = cubit.state as MasterViewLoaded;
    expect(state1.supalists.any((l) => l.name == 'List A'), isTrue);

    final added = state1.supalists.firstWhere((l) => l.name == 'List A');
    final id = added.id!;

    // remove
    await cubit.removeSupalist(id);
    final state2 = cubit.state as MasterViewLoaded;
    expect(state2.supalists.any((l) => l.id == id), isFalse);

    // delete database
    await cubit.deleteDatabase();
    // after delete, final loaded state should be empty
    final after = cubit.state as MasterViewLoaded;
    expect(after.supalists, isEmpty);

    await cubit.close();
  });
}
