import 'package:bloc/bloc.dart';
import 'package:supalist/bloc/detailview_states.dart';
import 'package:supalist/data/backend_connector.dart';
import 'package:supalist/data/database.dart';
import 'package:supalist/models/item.dart';
import 'package:supalist/models/supalist.dart';

class DetailViewCubit extends Cubit<DetailViewState> {
  DetailViewCubit(Supalist supalist) : super(DetailViewLoading(supalist: supalist)) {
    loadItems();
  }

  Future<void> loadItems() async {
    final state = DetailViewLoaded.fromLoading(
      this.state,
    );

    state.supalist.items = await DatabaseHelper.instance.getItems(state.supalist.id);
    sortItems();

    emit(state);
  }

  void sortItems() {
    state.supalist.items.sort((a, b) => a.checked.toString().compareTo(b.checked.toString()));
  }

  void addTileToggle() {
    final state = this.state as DetailViewLoaded;

    emit(state.copy(addTile: !state.addTile)..textController.clear());
  }

  void addItem(String title, bool keepAdding) async {
    final state = this.state as DetailViewLoaded;

    if (title.isEmpty) return;

    final itemExists = state.supalist.items.where(
      (item) => item.name == title,
    );

    if (itemExists.isNotEmpty) {
      final existingItem = itemExists.first;
      existingItem.history = false;
      existingItem.checked = false;
      await DatabaseHelper.instance.updateItem(existingItem);
    } else {
      final userId = getUserId();
      if (userId == null) return;

      final newItem = Item(
        name: title,
        checked: false,
        history: false,
        list: state.supalist.id,
        owner: userId,
      );

      state.supalist.items.add(newItem);
      await DatabaseHelper.instance.addItem(newItem);
    }

    emit(state.copy(addTile: keepAdding)..textController.clear());
  }

  void removeItem(String itemId) async {
    final state = this.state as DetailViewLoaded;

    final item = state.supalist.items.firstWhere((element) => element.id == itemId);
    item.history = true;
    await DatabaseHelper.instance.updateItem(item);

    emit(state.copy());
  }

  void deleteItem(String itemName) async {
    final state = this.state as DetailViewLoaded;

    final item = state.supalist.items.firstWhere((element) => element.name == itemName);
    state.supalist.items.remove(item);
    await DatabaseHelper.instance.removeItem(item.id);
    emit(state.copy());
  }

  void toggleItemChecked(Item item) async {
    final state = this.state as DetailViewLoaded;

    item.checked = !item.checked;
    emit(state.copy());

    await DatabaseHelper.instance.updateItem(item);
    await Future.delayed(const Duration(milliseconds: 300));
    sortItems();

    emit(state.copy());
  }

  void clearCheckedItems() async {
    final state = this.state as DetailViewLoaded;

    final checkedItems = state.supalist.items.where((item) => item.checked).toList();

    for (var item in checkedItems) {
      item.history = true;
      item.checked = false;
      await DatabaseHelper.instance.updateItem(item);
    }

    emit(state.copy());
  }
}