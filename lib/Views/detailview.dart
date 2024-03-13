import 'package:flutter/material.dart';

import 'package:supalist/Helper/database.dart';
import 'package:supalist/Helper/ui_model.dart';
import 'package:supalist/Models/item.dart';
import 'package:supalist/Models/supalist.dart';

class DetailView extends StatefulWidget{
  final Supalist supalist;
  const DetailView({super.key, required this.supalist});

  @override
  State<StatefulWidget> createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView>{
  bool addTile = false;

  Widget _buildDismissibleTile(Item item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(15)),
        color: Colors.red,
      ),
      child: Dismissible(
          key: UniqueKey(),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction){
            return showDialog(
              context: context,
              builder: (BuildContext context) {
                return DialogModel(
                    title: 'Confirm Dismiss',
                    content: const Text('Do you really want to remove this Item', style: TextStyle(fontSize: 20),),
                    onConfirmed: (){
                      setState(() {
                        widget.supalist.items.remove(item);
                        DatabaseHelper.instance.removeItem(item.id!);
                      });
                    }
                );
              },
            );
          },
          background: Container(
            padding: const EdgeInsets.only(right: 20),
            alignment: Alignment.centerRight,
            child: const Icon(
              Icons.delete,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.all(Radius.circular(15))
            ),
            child: CheckboxListTile(
              checkboxShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
              value: item.checked,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
              tileColor: Theme.of(context).colorScheme.surface,
              title: Text(item.name),
              onChanged: (value) => setState(() {item.checked = value!; DatabaseHelper.instance.updateItem(item);} ),
            )//expansionTile(transaction, memberMap)
          ),
      )
    );
  }

  Widget buildBody() {
    return Center(
      child: FutureBuilder<Supalist>(
        future: DatabaseHelper.instance.getList(widget.supalist.id!),
        builder: (BuildContext context, AsyncSnapshot<Supalist> snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          } else {
            return RefreshIndicator(
              child: snapshot.data!.items.isEmpty && !addTile ? 
                ListView(
                  physics: const BouncingScrollPhysics(parent:AlwaysScrollableScrollPhysics()),
                  padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height/2.5),
                  children: const [Center(child: Text('No items in list', style: TextStyle(fontSize: 20),),)],
                ) : 
                ListView.builder(
                  physics: const BouncingScrollPhysics(parent:AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.items.length + (addTile ? 1 : 0),
                  itemBuilder: (context, i) {
                    return i == snapshot.data!.items.length ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: TextField(
                        autofocus: true,
                        onSubmitted: (value) {
                          setState(() {
                            if (value.isNotEmpty) {
                              snapshot.data!.items.add(Item(name: value));
                              DatabaseHelper.instance.addItem(Item(name: value), widget.supalist.id!);
                            }
                            addTile = false;
                          });
                        },
                        decoration: TfDecorationModel(
                            context: context,
                            title: 'Add Item',
                        ),
                      ),
                    ) :  _buildDismissibleTile(snapshot.data!.items[i]);
                  }
                ),
              onRefresh: (){
                setState(() {});
                return Future(() => null);
              });
          }
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(widget.supalist.name),
        actions: [
          IconButton(
              onPressed: (){
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not implemented yet')));
              },
              icon: const Icon(Icons.edit)
          ),
        ],
      ),
      body: buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          setState(() {
            addTile = true;
          });
          //ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not implemented yet')));
        },//_showAddDialog,
        tooltip: 'Add Item',
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}