import 'package:powersync/powersync.dart';

const schema = Schema([
  Table('lists', [
    Column.text('timestamp'),
    Column.text('name'),
    Column.text('owner')
  ]),
  Table('items', [
    Column.text('timestamp'),
    Column.text('name'),
    Column.integer('checked'),
    Column.integer('history'),
    Column.text('owner'),
    Column.text('list')
  ])
]);