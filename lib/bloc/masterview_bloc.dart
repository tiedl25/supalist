import 'package:bloc/bloc.dart';
import 'package:supalist/bloc/masterview_states.dart';
import 'package:supalist/data/database.dart';
import 'package:supalist/models/supalist.dart';

class MasterViewCubit extends Cubit<MasterViewState> {
  late final DatabaseHelper databaseHelper;

  MasterViewCubit() : super(MasterViewLoading()) {
    databaseHelper = DatabaseHelper.instance;
    loadSupalists();
  }

  Future<void> loadSupalists() async {
    try {
      final supalists = await databaseHelper.getLists();
      emit(MasterViewLoaded(supalists: supalists));
    } catch (e) {
      // Handle error state if necessary
    }
  }

  Future<void> deleteDatabase() async {
    await databaseHelper.delete();
    emit(MasterViewLoading());
    await loadSupalists();
  }

  Future<void> removeSupalist(int id) async {
    final state = this.state as MasterViewLoaded;

    state.supalists.removeWhere((element) => element.id == id);
    DatabaseHelper.instance.remove(id);

    emit(MasterViewLoaded(supalists: state.supalists));
  }

  Future<void> addSupalist(String title) async {
    final state = this.state as MasterViewLoaded;

    final newSupalist = Supalist(name: title);

    state.supalists.add(newSupalist);
    newSupalist.id = await DatabaseHelper.instance.add(newSupalist);

    emit(MasterViewLoaded(supalists: state.supalists));
  }
}