import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supalist/data/database.dart';
import 'package:supalist/models/supalist.dart';
import 'package:supalist/bloc/detailview_states.dart';
import 'package:supalist/bloc/detailview_bloc.dart';

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
      tempDir = await Directory.systemTemp.createTemp('supalist_detail_test');
      PathProviderPlatform.instance = _FakePathProvider(tempDir.path);

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

  test('DetailViewCubit add/toggle/remove item', () async {
    if (!_sqliteAvailable) return;

    // ensure clean
    await DatabaseHelper.instance.delete();

    final list = Supalist(name: 'Test List', owner: 'tester');
    await DatabaseHelper.instance.addList(list);

    final cubit = DetailViewCubit(list);

    // wait for loaded
    await cubit.stream.firstWhere((s) => s is DetailViewLoaded);

  // add item
  final beforeLen = (cubit.state as DetailViewLoaded).supalist.items.length;
  cubit.addItem('New Item', false); // returns void
  await cubit.stream.firstWhere((s) => (s as DetailViewLoaded).supalist.items.length == beforeLen + 1);
  var state = cubit.state as DetailViewLoaded;
  expect(state.supalist.items.any((i) => i.name == 'New Item'), isTrue);

  final item = state.supalist.items.firstWhere((i) => i.name == 'New Item');
  expect(item.checked, isFalse);

  // toggle
  cubit.toggleItemChecked(item);
  await cubit.stream.firstWhere((s) => (s as DetailViewLoaded).supalist.items.firstWhere((it) => it.id == item.id).checked == true);
  state = cubit.state as DetailViewLoaded;
  final toggled = state.supalist.items.firstWhere((i) => i.id == item.id);
  expect(toggled.checked, isTrue);

  // remove
  final removeBefore = state.supalist.items.length;
  cubit.removeItem(item.id);
  await cubit.stream.firstWhere((s) => (s as DetailViewLoaded).supalist.items.length == removeBefore - 1);
  state = cubit.state as DetailViewLoaded;
  expect(state.supalist.items.any((i) => i.id == item.id), isFalse);

  await cubit.loadItems();
    await cubit.close();
  });
}
