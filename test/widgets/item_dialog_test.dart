import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supalist/ui/dialogs/itemdialog.dart';
import 'package:supalist/bloc/masterview_states.dart';
import 'package:supalist/bloc/masterview_bloc.dart';
import 'package:supalist/data/database.dart';
import 'package:supalist/resources/strings.dart';

class SpyMasterCubit extends Cubit<MasterViewState> implements MasterViewCubit {
  @override
  DatabaseHelper databaseHelper = DatabaseHelper.instance;

  String? lastAdded;

  SpyMasterCubit() : super(MasterViewLoading());

  @override
  Future<void> addSupalist(String title) async {
    lastAdded = title;
  }

  @override
  Future<void> deleteDatabase() async {}

  @override
  Future<void> loadSupalists() async {}

  @override
  Future<void> removeSupalist(int id) async {}
}

void main() {
  testWidgets('ItemDialog calls cubit.addSupalist when confirmed', (WidgetTester tester) async {
    final spy = SpyMasterCubit();

    // Mount the dialog directly inside the widget tree so it can access the provider.
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<MasterViewCubit>.value(
        value: spy,
        child: Scaffold(body: ItemDialog()),
      ),
    ));
    await tester.pumpAndSettle();

    // enter text
    await tester.enterText(find.byType(TextField), 'My New List');
    await tester.pumpAndSettle();

    // confirm by tapping OK (Strings.okText)
    await tester.tap(find.text(Strings.okText));
    await tester.pumpAndSettle();

    expect(spy.lastAdded, 'My New List');
  });
}
