import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supalist/resources/strings.dart';
import 'package:supalist/ui/widgets/ui_model.dart';
import 'package:supalist/ui/widgets/customDialog.dart';
import 'package:supalist/bloc/detailview_bloc.dart';
import 'package:supalist/bloc/detailview_states.dart';

class AuthDialog extends StatelessWidget {
  const AuthDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DetailViewCubit>();

    return CustomDialog(
      content: Text(
        Strings.wannaSignIn,
        style: TextStyle(fontSize: 20),
      ),
      onConfirmed: () => Navigator.pushReplacementNamed(context, '/auth'),
      onDismissed: () => cubit.closeShareDialog(),
      pop: false);
  }
}

class InviteDialog extends StatelessWidget {
  late BuildContext context;
  late DetailViewCubit cubit;

  TextEditingController tfController = TextEditingController();

  Future<void> showShareDialog(DetailViewShareDialogShowLink state) async {
    if (state.overlayEntry.mounted) {
      state.overlayEntry.remove();
    }

    await SharePlus.instance.share(ShareParams(
      text: state.message,
    ));

    cubit.closeShareDialog();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    this.cubit = context.read<DetailViewCubit>();

    return BlocConsumer<DetailViewCubit, DetailViewState>(
      bloc: cubit,
      listenWhen: (_, current) => current is DetailViewShareDialogListener,
      listener: (context, state) {
        switch (state.runtimeType) {
          case DetailViewShareDialogShowSnackBar:
            showOverlayMessage(
              context: context, 
              message: (state as DetailViewShareDialogShowSnackBar).message,
              backgroundColor: Theme.of(context).colorScheme.primary,
            );
            break;
          case DetailViewShareDialogShowLink:
            showShareDialog((state as DetailViewShareDialogShowLink));
            break;
        }
      },
      buildWhen: (_, current) => current is DetailViewShareDialog,
      builder: (context, state) {
        state as DetailViewShareDialog;

        return CustomDialog(
          pop: false,
          title: Strings.shareSupalistDialogTitle,
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(children: [
                TextField(
                  keyboardType: TextInputType.emailAddress,
                  controller: tfController,
                  decoration: TfDecorationModel(
                    context: context,
                    title: Strings.email,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9.@_-]'))
                  ],
                ),
              ]),
            ),
          ),
          onConfirmed: () {
            Overlay.of(context).insert(state.overlayEntry);

            cubit.showLink(tfController.text);
          },
          onDismissed: () => cubit.closeShareDialog(),
        );
      },
    );
  }
}
