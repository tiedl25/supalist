import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:supalist/bloc/detailview_bloc.dart';
import 'package:supalist/bloc/detailview_states.dart';
import 'package:supalist/data/supabase.dart';
import 'package:supalist/resources/strings.dart';
import 'package:supalist/resources/values.dart';
import 'package:supalist/ui/dialogs/invitedialog.dart';
import 'package:supalist/ui/widgets/ui_model.dart';
import 'package:supalist/models/item.dart';

class DetailView extends StatelessWidget {
  late final BuildContext context;
  late final DetailViewCubit cubit;

  void showInviteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: cubit,
          child: currentUser == null
            ? const AuthDialog()
            : InviteDialog(),
        );
      },
    );
  }

  Widget body() {
    return Center(
      child: BlocConsumer<DetailViewCubit, DetailViewState>(
          bloc: cubit,
          listenWhen: (_, current) => current is DetailViewListener,
          listener: (context, state) {
            switch (state.runtimeType) {
              case DetailViewShowSnackBar:
                showOverlayMessage(
                  context: context, 
                  message: (state as DetailViewShowSnackBar).message,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                );
                break;
              case DetailViewShowInviteDialog:
                showInviteDialog();
                break;
            }
          },
          buildWhen: (_, current) => current is DetailViewLoaded || current is DetailViewLoading,
          builder: (context, state) {
            if (state is DetailViewLoading) {
              return const CircularProgressIndicator();
            }
            state as DetailViewLoaded;

            final items = state.supalist.items.where((item) => item.history == false).toList();

            return RefreshIndicator(
              child: state.supalist.items.isEmpty && !state.addTile
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
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 160, top: 16),
                      itemCount: items.length + (state.addTile ? 1 : 0),
                      itemBuilder: (context, i) {
                        return i == items.length
                            ? ItemSuggestion(cubit: cubit)
                            : DismissibleItem(cubit: cubit, context: context, item: items[i]);
                      }),
              onRefresh: () async => await cubit.loadItems(),
            );
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    cubit = context.read<DetailViewCubit>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: BlocBuilder<DetailViewCubit, DetailViewState>(
          builder: (context, state) {
            return Text(state.supalist.name);
          },
        ),
        actions: [
          IconButton(
              onPressed: () {
                showOverlayMessage(context: context, message: Strings.notImplementedText);
              },
              icon: const Icon(Icons.edit)),
          IconButton(
              onPressed: () => cubit.showShareDialog(),
              icon: const Icon(Icons.person_add)),
        ],
      ),
      body: body(),
      floatingActionButton: BlocBuilder<DetailViewCubit, DetailViewState>(
        builder: (context, state) {
          return Align(
            alignment: Alignment.bottomRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state is DetailViewLoaded)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: state.addTile ? FloatingActionButton(
                        onPressed: () => cubit.addTileToggle(),
                        tooltip: Strings.removeItemTile,
                        backgroundColor: const Color.fromARGB(255, 240, 73, 106),
                        foregroundColor: Colors.white,
                        heroTag: "btn1",
                        child: const Icon(Icons.remove),
                      )
                    : FloatingActionButton(
                        onPressed: () => cubit.clearCheckedItems(),
                        tooltip: Strings.clearCheckedItems,
                        backgroundColor: const Color.fromARGB(255, 72, 220, 139),
                        foregroundColor: Colors.white,
                        heroTag: "btn1",
                        child: const Icon(Icons.clear_all),
                    ),
                  ),
                FloatingActionButton(
                  onPressed: () => state is DetailViewLoading
                      ? null
                      : (state as DetailViewLoaded).addTile ? cubit.addItem(state.textController.text, true) : cubit.addTileToggle(),
                  tooltip: Strings.addItemText,
                  foregroundColor: Colors.white,
                  heroTag: "btn2",
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DismissibleItem extends StatelessWidget {
  const DismissibleItem({
    super.key,
    required this.cubit,
    required this.context,
    required this.item,
  });

  final DetailViewCubit cubit;
  final BuildContext context;
  final Item item;

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: 5),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(Values.borderRadius)),
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
                onPressed: (_) => cubit.removeItem(item.id),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: Strings.deleteText,
              ),
            ],
          ),
          child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: const BorderRadius.all(
                      Radius.circular(Values.borderRadius))),
              child: CheckboxListTile(
                checkboxShape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                value: item.checked,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(Values.borderRadius)),
                ),
                tileColor: Theme.of(context).colorScheme.surfaceContainer,
                title: Text(item.name),
                onChanged: (value) => cubit.toggleItemChecked(item),
              )),
        ));
  }
}

class ItemSuggestion extends StatelessWidget {
  const ItemSuggestion({
    super.key,
    required this.cubit,
  });

  final DetailViewCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DetailViewCubit, DetailViewState>(
      builder: (context, state) {
        state as DetailViewLoaded;

        return Autocomplete(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') {
              return const Iterable<String>.empty();
            }
            
            return state.supalist.items.where((Item item) => item.history == true && item.name.toLowerCase().contains(textEditingValue.text.toLowerCase())).map((e) => e.name);
        },
        textEditingController: state.textController,
        focusNode: FocusNode(),
        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
          return TextField(
            autofocus: true,
            focusNode: focusNode,
            controller: textEditingController,
            decoration: TfDecorationModel(
              context: context,
              title: Strings.addItemText,
            ),
            onSubmitted: (_) => cubit.addItem(state.textController.text, false),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 200.0,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: options.map<Widget>((option) {
                      return ListTile(
                        contentPadding: const EdgeInsets.only(left: 20, right: 15),
                        title: Text(option),
                        onTap: () => onSelected(option),
                        trailing: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => cubit.deleteItem(option), 
                          icon: const Icon(Icons.delete),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ),)
          );
        },
        onSelected: (String selection) => cubit.addItem(selection, false),
      );
    }); 
  }
}
