import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supalist/ui/views/masterview.dart';
import 'package:supalist/bloc/masterview_bloc.dart';
import 'package:supalist/bloc/masterview_states.dart';
import 'package:supalist/models/supalist.dart';
import 'package:supalist/data/database.dart';

class FakeMasterCubit extends Cubit<MasterViewState> implements MasterViewCubit {
  @override
  DatabaseHelper databaseHelper = DatabaseHelper.instance;

  FakeMasterCubit(List<Supalist> lists) : super(MasterViewLoaded(supalists: lists));

  @override
  Future<void> addSupalist(String title) async {}

  @override
  Future<void> deleteDatabase() async {}

  @override
  Future<void> loadSupalists() async {}

  @override
  Future<void> removeSupalist(String id) async {}
}

void main() {
  testWidgets('MasterView shows supalist title', (WidgetTester tester) async {
    final supalist = Supalist(id: '1', name: 'My List', owner: 'tester');
    final cubit = FakeMasterCubit([supalist]);

    await tester.pumpWidget(MaterialApp(
      routes: {
        '/detail': (context) => const SizedBox.shrink(),
      },
      home: BlocProvider<MasterViewCubit>.value(
        value: cubit,
        child: MasterView(),
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.text('My List'), findsOneWidget);
  });
}
