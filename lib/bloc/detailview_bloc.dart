import 'package:bloc/bloc.dart';
import 'package:supalist/bloc/detailview_states.dart';
import 'package:supalist/data/database.dart';
import 'package:supalist/data/supabase.dart';
import 'package:supalist/models/access_rights.dart';
import 'package:supalist/models/item.dart';
import 'package:supalist/models/supalist.dart';
import 'package:supalist/resources/strings.dart';

class DetailViewCubit extends Cubit<DetailViewState> {
  DetailViewCubit(Supalist supalist) : super(DetailViewLoading(supalist: supalist)) {
    loadItems();
  }

  Future<void> loadItems() async {
    final state = DetailViewLoaded.fromLoading(
      this.state,
    );

    state.supalist.items = await DatabaseHelper.instance.getItems(id: state.supalist.id);
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

  void showShareDialog() async {
    if (currentUser != null) {
      if (state.supalist.owner != userId) {
        emit(DetailViewShowSnackBar(
          supalist: state.supalist,
          message: Strings.notAuthorizedShareItem
        ));
        return;
      }
    }
    
    final newState = DetailViewShareDialog.from((state as DetailViewLoaded));

    emit(DetailViewShowInviteDialog(supalist: state.supalist));

    emit(newState);
  }

  void closeShareDialog() {
    emit(DetailViewLoaded.from(state));
  }

  void showLink(String email) async {
    final state = (this.state as DetailViewShareDialog).copy();

    AccessRights permission = AccessRights(
      list: state.supalist.id,
      userEmail: email.isEmpty ? null : email,
      expirationDate: DateTime.now().add(const Duration(days: 1)));

    final result = await DatabaseHelper.instance.addSharePermission(permission);

    if (!result.isSuccess) {
      state.overlayEntry.remove();
      emit(DetailViewShareDialogShowSnackBar(supalist: state.supalist, overlayEntry: state.overlayEntry, message: result.message!));
    } else {
      permission = result.value!;
      String message = Strings.invitedToSupalist;
      message += 'https://tmc.tiedl.rocks/supalist?id=${permission.id}';
      emit(DetailViewShareDialogShowLink(supalist: state.supalist, overlayEntry: state.overlayEntry, message: message));
    }
    
    emit(state);
  }
}