import 'package:bloc/bloc.dart';
import 'package:supalist/bloc/detailview_states.dart';
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

    state.supalist.items = await DatabaseHelper.instance.getItems(state.supalist.id!);

    emit(state);
  }

  void addTileToggle() {
    final state = this.state as DetailViewLoaded;

    emit(state.copy(addTile: !state.addTile));
  }

  void addItem(String title) async {
    final state = this.state as DetailViewLoaded;

    if (title.isEmpty) return;

    final newItem = Item(
      name: title,
      checked: false,
    );

    state.supalist.items.add(newItem);
    newItem.id = await DatabaseHelper.instance.addItem(newItem, state.supalist.id!);

    emit(state.copy(addTile: false));
  }

  void removeItem(int itemId) async {
    final state = this.state as DetailViewLoaded;

    state.supalist.items.removeWhere((element) => element.id == itemId);
    await DatabaseHelper.instance.removeItem(itemId);

    emit(state.copy());
  }

  void toggleItemChecked(Item item) async {
    final state = this.state as DetailViewLoaded;

    item.checked = !item.checked;
    await DatabaseHelper.instance.updateItem(item);

    emit(state.copy());
  }
}