import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supalist/bloc/masterview_bloc.dart';
import 'package:supalist/resources/strings.dart';
import 'package:supalist/ui/widgets/ui_model.dart';

class ItemDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MasterViewCubit>();
    final TextEditingController controller = TextEditingController();

    return DialogModel(
      title: Strings.addSupalistText,
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: TextField(
            controller: controller,
            autofocus: true,
            decoration: TfDecorationModel(
                context: context,
                title: Strings.nameText,
            ),
          ),
        )
      ),
      onConfirmed: () => cubit.addSupalist(controller.text)
      );
  }
}