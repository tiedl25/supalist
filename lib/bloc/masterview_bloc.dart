import 'package:app_links/app_links.dart';
import 'package:bloc/bloc.dart';
import 'package:supalist/bloc/masterview_states.dart';
import 'package:supalist/data/database.dart';
import 'package:supalist/data/supabase.dart';
import 'package:supalist/models/supalist.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MasterViewCubit extends Cubit<MasterViewState> {
  final SharedPreferences prefs;
  late final DatabaseHelper databaseHelper;
  bool _initialLinkProcessed = false;

  MasterViewCubit({required this.prefs}) : super(MasterViewLoading()) {
    databaseHelper = DatabaseHelper.instance;
    loadSupalists();
    handleIncomingLinks();
  }

  void handleIncomingLinks() {
    final appLinks = AppLinks();
    if (!_initialLinkProcessed) {
      appLinks.getInitialLink().then((Uri? uri) async {
        if (state.runtimeType == MasterViewInvitationDialog) {
          return;
        }

        if (uri != null) showInvitationDialog(uri.queryParameters['id']);
      });
      _initialLinkProcessed = true;
    }

    appLinks.uriLinkStream.listen((Uri? uri) async {
      if (uri != null) {
        if (state.runtimeType == MasterViewInvitationDialog) {
          return;
        }

        showInvitationDialog(uri.queryParameters['id']);
      }
    }, onError: (err) {
      print('Error occurred: $err');
    });
  }

  void showInvitationDialog(final String? permissionId) {
    if (permissionId != null) {
      final newState = MasterViewInvitationDialog(
        permissionId: permissionId
      );

      emit(MasterViewShowInvitationDialog());

      emit(newState);
    }
  }

  Future<void> acceptInvitation() async {
    final id = (state as MasterViewInvitationDialog).permissionId;
    final result = await DatabaseHelper.instance.confirmPermission(id);
    if (result.isSuccess) {
      final newState = MasterViewLoading();
      emit(newState);

      loadSupalists();
    } else {
      final newState = MasterViewShowSnackBar(
        message: result.message!
      );

      emit(newState);
    }
  }

  void declineInvitation() {
    final newState = MasterViewLoading();
    emit(newState);
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

  void showAddDialog() {
    final newState = MasterViewAddDialog.from(state);

    emit(MasterViewShowAddDialog());

    emit(newState);
  }

  Future<void> deleteDatabase() async {
    await databaseHelper.delete();
    emit(MasterViewLoading());
    await loadSupalists();
  }

  Future<void> removeSupalist(String id) async {
    final state = this.state as MasterViewLoaded;

    state.supalists.removeWhere((element) => element.id == id);
    DatabaseHelper.instance.remove(id);

    emit(MasterViewLoaded(supalists: state.supalists));
  }

  Future<void> addSupalist(String title) async {
    final state = this.state as MasterViewLoaded;

    final newSupalist = Supalist(name: title, owner: userId);

    state.supalists.add(newSupalist);
    await DatabaseHelper.instance.addList(newSupalist);

    emit(MasterViewLoaded(supalists: state.supalists));
  }
}