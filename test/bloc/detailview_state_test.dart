import 'package:flutter_test/flutter_test.dart';
import 'package:supalist/bloc/detailview_states.dart';
import 'package:supalist/models/supalist.dart';

void main() {
  test('DetailViewLoaded copy and fromLoading', () {
    final s = Supalist(id: '1', name: 'List A', owner: 'tester');
    final loading = DetailViewLoading(supalist: s);

    final loaded = DetailViewLoaded.fromLoading(loading, addTile: true);
    expect(loaded.supalist, s);
    expect(loaded.addTile, true);

    final copied = loaded.copy(addTile: false);
    expect(copied.addTile, false);
    expect(copied.supalist, loaded.supalist);
  });
}
