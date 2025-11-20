import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:supalist/bloc/masterview_bloc.dart';
import 'package:supalist/bloc/masterview_states.dart';
import 'package:supalist/ui/dialogs/itemdialog.dart';
import 'package:supalist/models/supalist.dart';
import 'package:supalist/ui/widgets/ui_model.dart';

class MasterView extends StatelessWidget {
  late final MasterViewCubit cubit;
  late final BuildContext context;

  MasterView({
    super.key,
  });

  void showAddDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: cubit,
          child: ItemDialog(),
        );
      });
  }

  Widget body() {
    return Center(
      child: BlocBuilder<MasterViewCubit, MasterViewState>(
          builder: (context, state) {
        if (state is MasterViewLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        state as MasterViewLoaded;
        final listOfSupalists = state.supalists;
        return RefreshIndicator(
            child: listOfSupalists.isEmpty
                ? ListView(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height / 2.5),
                    children: const [
                      Center(
                        child: Text(
                          'No items in list',
                          style: TextStyle(fontSize: 20),
                        ),
                      )
                    ],
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.all(16),
                    itemCount: listOfSupalists.length,
                    itemBuilder: (context, i) {
                      return dismissible(listOfSupalists[i]);
                    }),
            onRefresh: () async => await cubit.loadSupalists());
      }),
    );
  }

  Widget dismissible(Supalist supalist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: const BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
      child: Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.endToStart,
        onDismissed: (_) async => await cubit.removeSupalist(supalist.id!),
        confirmDismiss: (direction) {
          return showDialog(
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(builder: (context, setState) {
                return DialogModel(
                    title: 'Confirm Dismiss',
                    content: Container(
                      padding: const EdgeInsets.all(5),
                      child: const Text(
                        'Do you really want to remove this Item',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    onConfirmed: () {});
              });
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
        child: tile(supalist),
      ),
    );
  }

  Widget tile(Supalist supalist) {
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
        title: Text(
          supalist.name,
          style: const TextStyle(fontSize: 20),
        ),
        onTap: () => Navigator.pushNamed(context, '/detail', arguments: supalist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    cubit = context.read<MasterViewCubit>();

    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          title: const Text('Supalist'),
          actions: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/settings'), 
              icon: const Icon(Icons.settings)
            )
          ],
        ),
        body: body(),
        floatingActionButton: SpeedDial(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15))),
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
              onTap: () => showAddDialog(),
            ),
            if (kDebugMode)
              SpeedDialChild(
                child: const Icon(Icons.remove),
                onTap: () async => await cubit.deleteDatabase(),
              ),
          ],
        ));
  }
}
