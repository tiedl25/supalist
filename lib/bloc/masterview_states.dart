import 'package:supalist/models/supalist.dart';

abstract class MasterViewState {}

class MasterViewLoading extends MasterViewState {}

class MasterViewLoaded extends MasterViewState {
  final List<Supalist> supalists;

  MasterViewLoaded({required this.supalists});
}

class MasterViewAddDialog extends MasterViewLoaded {
  MasterViewAddDialog({required super.supalists});

  factory MasterViewAddDialog.from(state) {
    return MasterViewAddDialog(supalists: state.supalists);
  }
}

class MasterViewInvitationDialog extends MasterViewState {
  final String permissionId;
  
  MasterViewInvitationDialog({required this.permissionId});
}



abstract class MasterViewListener extends MasterViewState {}

class MasterViewShowAddDialog extends MasterViewListener {
  MasterViewShowAddDialog();
}

class MasterViewShowInvitationDialog extends MasterViewListener {
  MasterViewShowInvitationDialog();
}

class MasterViewShowSnackBar extends MasterViewListener {
  final String message;

  MasterViewShowSnackBar({required this.message});
}

class MasterViewPushAuthView extends MasterViewListener {
  MasterViewPushAuthView();
}