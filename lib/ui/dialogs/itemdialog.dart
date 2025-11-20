import 'package:flutter/material.dart';
import 'package:supalist/ui/widgets/ui_model.dart';
import 'package:supalist/models/supalist.dart';
import 'package:supalist/data/database.dart';

class ItemDialog extends StatefulWidget {
  final Function updateItemList;

  const ItemDialog({super.key, required this.updateItemList});

  @override
  State<StatefulWidget> createState() {
    return _ItemDialogState();
  }
}

class _ItemDialogState extends State<ItemDialog>{
  String title = '';

  @override
  Widget build(BuildContext context) {
    return DialogModel(
            title: 'Add a new list',
            content: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: TextField(
                  autofocus: true,
                  onChanged: (value) {
                    setState(() {
                      title = value;
                    });
                  },
                  decoration: TfDecorationModel(
                      context: context,
                      title: 'Name',
                  ),
                ),
              )
            ),
            onConfirmed:  (){
              widget.updateItemList(Supalist(name: title));
              DatabaseHelper.instance.add(Supalist(name: title));
            }
            );
  }
}