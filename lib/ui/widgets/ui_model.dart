import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supalist/resources/strings.dart';
import 'package:supalist/resources/values.dart';
import 'package:supalist/ui/widgets/overlayLoadingScreen.dart';
import 'package:supalist/ui/widgets/overlayMessage.dart';

class DialogModel extends StatelessWidget {
  final String? title;
  final Widget content;
  final Function? onConfirmed;
  final String leftText;
  final String rightText;
  final EdgeInsets insetPadding;
  final EdgeInsets contentPadding;
  final Alignment alignment;
  final bool scrollable;

  const DialogModel({
    super.key,
    this.title,
    required this.content,
    this.onConfirmed,
    this.leftText=Strings.cancelText,
    this.rightText=Strings.okText,
    this.insetPadding=const EdgeInsets.all(15),
    this.contentPadding=const EdgeInsets.all(20),
    this.alignment=Alignment.bottomCenter,
    this.scrollable=true
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: AlertDialog(
          elevation: 0,
          alignment: alignment,
          insetPadding: insetPadding,
          contentPadding: contentPadding,
          scrollable: scrollable,
          title: title != null ? Text(title!) : null,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Values.borderRadius))),
          backgroundColor: Theme.of(context).colorScheme.surface,
          content: content,
          actions: onConfirmed != null ? [
            const Divider(
              thickness: 0.5,
              indent: 0,
              endIndent: 0,
            ),
            IntrinsicHeight(
              child: Container(
                padding: const EdgeInsets.all(0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          child: Text(leftText, style: Theme.of(context).textTheme.labelLarge,),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                        )
                    ),
                    const VerticalDivider(
                      indent: 5,
                      endIndent: 5,
                    ),
                    Expanded(
                      child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          child: Text(rightText, style: Theme.of(context).textTheme.labelLarge,),
                          onPressed: () {
                            onConfirmed!();
                            Navigator.of(context).pop(true);
                          }
                      ),
                    ),
                  ],
                ),
              )
            ),
          ] : null
        )
    );
  }
}

class ErrorDialog extends StatelessWidget {
  final String text;

  const ErrorDialog(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return DialogModel(content: Text(text, style: const TextStyle(color: Colors.red)), alignment: Alignment.center,);
  }

}

class TfDecorationModel extends InputDecoration {
  TfDecorationModel({required BuildContext context, required String title, IconButton? icon}) : super(
      suffixIcon: icon,
      hintText: title,
      fillColor: Theme.of(context).colorScheme.surfaceContainer,
      filled: true,
      enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(Values.borderRadius)),
          borderSide: BorderSide(style: BorderStyle.none)
      ),
      focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(Values.borderRadius)),
          borderSide: BorderSide(color: Colors.blue)
      ),
      errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(Values.borderRadius)),
          borderSide: BorderSide(color: Colors.red)
      )
  );
}

class PillModel extends StatelessWidget{
  final Color color;
  final Widget child;

  const PillModel({
    super.key,
    required this.color,
    required this.child
  });

  @override
  Widget build(BuildContext context){
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(style: BorderStyle.none, width: 0),
        borderRadius: const BorderRadius.all(Radius.circular(Values.borderRadius)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      margin: const EdgeInsets.all(2),
      child: child
    );
  }
}

void showOverlayMessage({
  required BuildContext context,
  required String message,
  Color backgroundColor = Colors.black,
  Color textColor = Colors.white,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlayEntry = OverlayMessage(
    message: message, 
    backgroundColor: backgroundColor, 
    textColor: textColor
  );
  Overlay.of(context).insert(overlayEntry);
  Timer(duration, () => overlayEntry.remove());
}

Future<void> showLoadingEntry({
  required BuildContext context,
  required Function onWait
}) async {
  final overlayEntry = OverlayLoadingScreen();
  Overlay.of(context).insert(overlayEntry);
  await onWait();
  overlayEntry.remove();
}
