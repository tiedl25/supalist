import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supalist/ui/views/detailview.dart';
import 'package:supalist/bloc/detailview_states.dart';
import 'package:supalist/models/supalist.dart';
import 'package:supalist/models/item.dart';
import 'package:supalist/bloc/detailview_bloc.dart';

class FakeDetailCubit extends Cubit<DetailViewState> implements DetailViewCubit {
  FakeDetailCubit(Supalist s) : super(DetailViewLoaded(supalist: s, addTile: false));

  @override
  Future<void> loadItems() async {}

  @override
  void addTileToggle() {
    final state = this.state as DetailViewLoaded;
    emit(state.copy(addTile: !state.addTile));
  }

  @override
  void addItem(String title, bool keepAdding) async {
    if (title.isEmpty) return;
    final state = this.state as DetailViewLoaded;
    final newItem = Item(id: DateTime.now().millisecondsSinceEpoch, name: title);
    state.supalist.items.add(newItem);
    emit(state.copy());
  }

  @override
  void removeItem(int itemId) async {
    final state = this.state as DetailViewLoaded;
    state.supalist.items.removeWhere((e) => e.id == itemId);
    emit(state.copy());
  }

  @override
  void toggleItemChecked(Item item) async {
    final state = this.state as DetailViewLoaded;
    final idx = state.supalist.items.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      state.supalist.items[idx].checked = !state.supalist.items[idx].checked;
      emit(state.copy());
    }
  }
}

void main() {
  testWidgets('DetailView shows items and toggles checkbox', (WidgetTester tester) async {
    final s = Supalist(id: 1, name: 'List A');
    s.items.add(Item(id: 10, name: 'Item 1', checked: false));

    final cubit = FakeDetailCubit(s);

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<DetailViewCubit>.value(
        value: cubit,
        child: DetailView(),
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.text('Item 1'), findsOneWidget);

    // Tap the checkbox to toggle
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    // After toggle, the cubit updated the item; verify state change
    final state = cubit.state as DetailViewLoaded;
    expect(state.supalist.items.first.checked, isTrue);
  });
}
