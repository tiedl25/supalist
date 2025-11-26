import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:supalist/bloc/masterview_bloc.dart';
import 'package:supalist/bloc/masterview_states.dart';
import 'package:supalist/resources/strings.dart';
import 'package:supalist/resources/values.dart';
import 'package:supalist/ui/dialogs/itemdialog.dart';
import 'package:supalist/models/supalist.dart';

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
                          Strings.noItemsInListText,
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
        borderRadius: BorderRadius.all(Radius.circular(Values.borderRadius)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Slidable(
        key: ValueKey(supalist.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => cubit.removeSupalist(supalist.id!),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: Strings.deleteText,
            ),
          ],
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
        borderRadius: const BorderRadius.all(Radius.circular(Values.borderRadius)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Values.borderRadius)),
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
          title: const Text(Strings.appName),
          actions: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/settings'), 
              icon: const Icon(Icons.settings)
            )
          ],
        ),
        body: body(),
        floatingActionButton: kDebugMode
          ? SpeedDial(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(Values.borderRadius))),
            spacing: 5,
            animatedIcon: AnimatedIcons.menu_close,
            animatedIconTheme: const IconThemeData(size: 22.0),
            foregroundColor: Colors.white,
            curve: Curves.bounceIn,
            overlayColor: Colors.black,
            overlayOpacity: 0.5,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.add),
                onTap: () => showAddDialog(),
              ),
              SpeedDialChild(
                child: const Icon(Icons.remove),
                onTap: () async => await cubit.deleteDatabase(),
              ),
              SpeedDialChild(
                child: const Icon(Icons.bug_report),
                onTap: () async => await cubit.addSupalist('Debug List ${DateTime.now().millisecondsSinceEpoch}'),
              ),
            ],
          )
          : FloatingActionButton(
            onPressed: () => showAddDialog(),
            tooltip: Strings.addSupalistText,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        );
  }
}
