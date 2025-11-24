import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:supalist/bloc/detailview_bloc.dart';
import 'package:supalist/bloc/detailview_states.dart';
import 'package:supalist/ui/widgets/ui_model.dart';
import 'package:supalist/models/item.dart';

class DetailView extends StatelessWidget {
  late final BuildContext context;
  late final DetailViewCubit cubit;

  Widget dismissibleTile(Item item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(15)),
        color: Colors.red,
      ),
      clipBehavior: Clip.hardEdge,
      child: Slidable(
        key: ValueKey(item.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => cubit.removeItem(item.id!),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(15))),
          child: CheckboxListTile(
            checkboxShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
            value: item.checked,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            tileColor: Theme.of(context).colorScheme.surface,
            title: Text(item.name),
            onChanged: (value) => cubit.toggleItemChecked(item),
          )
        ),
      )
    );
  }

  Widget body() {
    return Center(
      child: BlocBuilder<DetailViewCubit, DetailViewState>(
        bloc: cubit,
        builder: (context, state) {
          if (state is DetailViewLoading) {
            return const CircularProgressIndicator();
          }
          state as DetailViewLoaded;

          return RefreshIndicator(
            child: state.supalist.items.isEmpty && !state.addTile
              ? ListView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  padding: EdgeInsets.symmetric(
                      vertical:
                          MediaQuery.of(context).size.height / 2.5),
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
                  itemCount:
                      state.supalist.items.length + (state.addTile ? 1 : 0),
                  itemBuilder: (context, i) {
                    return i == state.supalist.items.length
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: TextField(
                              autofocus: true,
                              onSubmitted: (value) => cubit.addItem(value),
                              decoration: TfDecorationModel(
                                context: context,
                                title: 'Add Item',
                              ),
                            ),
                          )
                        : dismissibleTile(state.supalist.items[i]);
                  }),
              onRefresh: () async => await cubit.loadItems(),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    cubit = context.read<DetailViewCubit>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: BlocBuilder<DetailViewCubit, DetailViewState>(
          builder: (context, state) {
            return Text(state.supalist.name);
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Not implemented yet')));
            },
            icon: const Icon(Icons.edit)),
        ],
      ),
      body: body(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => cubit.addTileToggle(),
        tooltip: 'Add Item',
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
