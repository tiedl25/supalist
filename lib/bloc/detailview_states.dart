import 'package:flutter/widgets.dart';
import 'package:supalist/models/supalist.dart';
import 'package:supalist/ui/widgets/overlayLoadingScreen.dart';

abstract class DetailViewState {
  final Supalist supalist;
  DetailViewState({required this.supalist});
}

class DetailViewLoading extends DetailViewState {
  DetailViewLoading({required super.supalist});
}

class DetailViewLoaded extends DetailViewState {
  final TextEditingController textController;
  bool addTile;

  DetailViewLoaded({required super.supalist, TextEditingController? textController, this.addTile = false}) : textController = textController ?? TextEditingController();

  DetailViewLoaded copy({Supalist? supalist, TextEditingController? textController, bool? addTile}) {
    return DetailViewLoaded(
        supalist: supalist ?? this.supalist, textController: textController ?? this.textController, addTile: addTile ?? this.addTile);
  }

  factory DetailViewLoaded.fromLoading(state, {bool addTile = false}) {
    return DetailViewLoaded(supalist: state.supalist, addTile: addTile);
  }

  factory DetailViewLoaded.from(final state) {
    return DetailViewLoaded(supalist: state.supalist, addTile: state.addTile);
  }
}

class DetailViewShareDialog extends DetailViewLoaded {
  final OverlayEntry overlayEntry;

  DetailViewShareDialog({required super.supalist, super.textController, super.addTile, overlayEntry}) : overlayEntry = overlayEntry ?? OverlayLoadingScreen();

  DetailViewShareDialog copy({Supalist? supalist, TextEditingController? textController, bool? addTile, OverlayEntry? overlayEntry}) {
    return DetailViewShareDialog(
        supalist: supalist ?? this.supalist, 
        textController: textController ?? this.textController, 
        addTile: addTile ?? this.addTile,
        overlayEntry: overlayEntry ?? this.overlayEntry);
  }

  factory DetailViewShareDialog.from(final state) {
    return DetailViewShareDialog(supalist: state.supalist);
  }
}



abstract class DetailViewListener extends DetailViewState {
  DetailViewListener({required super.supalist});
}

class DetailViewShowSnackBar extends DetailViewListener {
  final String message;
  DetailViewShowSnackBar({required super.supalist, required this.message});
}

class DetailViewShowInviteDialog extends DetailViewListener {
  DetailViewShowInviteDialog({required super.supalist});
}

abstract class DetailViewShareDialogListener extends DetailViewShareDialog {
  DetailViewShareDialogListener({required super.supalist, super.overlayEntry});
}

class DetailViewShareDialogShowSnackBar extends DetailViewShareDialogListener {
  final String message;
  DetailViewShareDialogShowSnackBar({required super.supalist, super.overlayEntry, required this.message});
}

class DetailViewShareDialogShowLink extends DetailViewShareDialogListener {
  final String message;
  DetailViewShareDialogShowLink({required super.supalist, super.overlayEntry, required this.message});
}