
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:supalist/ui/dialogs/itemdialog.dart';
import 'package:supalist/data/database.dart';
import 'package:supalist/models/supalist.dart';
import 'package:supalist/ui/views/detailview.dart';
  
import 'package:supalist/ui/views/settingsview.dart';
import 'package:supalist/ui/widgets/ui_model.dart';

class MasterView extends StatefulWidget{
  final Function updateTheme;

  const MasterView({
    super.key,
    required this.updateTheme,
  });

  @override
  State<StatefulWidget> createState() => _MasterViewState();
}


class _MasterViewState extends State<MasterView>{
  List<Supalist> listOfSupalists = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Supalist'),
        actions: [
          IconButton(
              onPressed: _pushSettingsView,
              icon: const Icon(Icons.settings
              )
          )
        ],
      ),
      body: _buildBody(),
      floatingActionButton: SpeedDial(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
        spacing: 5,
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: const IconThemeData(size: 22.0),
        foregroundColor: Colors.white,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        children: [
          SpeedDialChild(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
            onTap: _showAddDialog,
          ),
          if(kDebugMode) SpeedDialChild(
            child: const Icon(Icons.remove),
            onTap: () async {
              setState(() {
                DatabaseHelper.instance.delete();
              });
            }
          ),
        ],
      )
    );
  }

  Widget _buildBody() {
    return Center(
      child: FutureBuilder<List<Supalist>>(
        future: DatabaseHelper.instance.getLists(),
        builder: (BuildContext context, AsyncSnapshot<List<Supalist>> snapshot) {
          if (!snapshot.hasData){
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isNotEmpty) {
            listOfSupalists = snapshot.data!;
          }
          return RefreshIndicator(
              child: snapshot.data!.isEmpty ?
              ListView(
                physics: const BouncingScrollPhysics(parent:AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height/2.5),
                children: const [Center(child: Text('No items in list', style: TextStyle(fontSize: 20),),)],
              )
                  : ListView.builder(
                physics: const BouncingScrollPhysics(parent:AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, i) {
                  return _buildDismissible(snapshot.data![i]);
                }
              ),
              onRefresh: (){
                setState(() {});
                return Future(() => null);
              });
        }
      ),
    );
  }
  Widget _buildDismissible(Supalist supalist){
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: const BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
      child: Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.endToStart,
        onDismissed: (context) async {
          setState(() {
            listOfSupalists.removeWhere((element) => element.id == supalist.id);
          });
          DatabaseHelper.instance.remove(supalist.id!);
        },
        confirmDismiss: (direction){
          return showDialog(
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(
                  builder: (context, setState){
                    return DialogModel(
                        title: 'Confirm Dismiss',
                        content: Container(
                                padding: const EdgeInsets.all(5),
                                child: const Text('Do you really want to remove this Item', style: TextStyle(fontSize: 20),),
                              ),
                        onConfirmed: (){}
                    );
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
        child: _buildRow(supalist),
      ),
    );
  }

  Widget _buildRow(Supalist supalist) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(style: BorderStyle.none),
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          tileColor: Theme.of(context).colorScheme.surface,
          title: Text(supalist.name, style: const TextStyle(fontSize: 20),),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context){
                  return DetailView(supalist: supalist,);
                },
              ),
            );
          },
      ),
    );
  }

  _showAddDialog(){
    showDialog(
        context: context,
        barrierDismissible: true, // user must tap button!
        builder: (BuildContext context){
          return ItemDialog(updateItemList: (itemlist) => setState(() => listOfSupalists.add(itemlist)),);
        });
  }

  void _pushSettingsView(){
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context){
          return SettingsView(setParentState: setState, updateTheme: widget.updateTheme,);
        },
      ),
    );
  }

  void _pushDetailView(){
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context){
          return DetailView(supalist: listOfSupalists[0],);
        },
      ),
    );
  }
}