import 'package:powersync/powersync.dart';

const schema = Schema([
  Table('lists', [
    Column.text('timestamp'),
    Column.text('name'),
    Column.text('owner')
  ], viewName: 'lists'),
  Table('items', [
    Column.text('timestamp'),
    Column.text('name'),
    Column.integer('checked'),
    Column.integer('history'),
    Column.text('owner'),
    Column.text('list')
  ], viewName: 'items'),
  Table('accessRights', [
    Column.text('list'),
    Column.text('user'),
    Column.text('userEmail'),
    Column.text('expirationDate')
  ]),
  Table.localOnly('local_lists', [
    Column.text('timestamp'),
    Column.text('name'),
    Column.text('owner')
  ], viewName: 'inactive_local_lists'),
  Table.localOnly('local_items', [
    Column.text('timestamp'),
    Column.text('name'),
    Column.integer('checked'),
    Column.integer('history'),
    Column.text('owner'),
    Column.text('list')
  ], viewName: 'inactive_local_items')
]);

const localSchema = Schema([
  Table('lists', [
    Column.text('timestamp'),
    Column.text('name'),
    Column.text('owner')
  ], viewName: 'inactive_synced_lists'),
  Table('items', [
    Column.text('timestamp'),
    Column.text('name'),
    Column.integer('checked'),
    Column.integer('history'),
    Column.text('owner'),
    Column.text('list')
  ], viewName: 'inactive_synced_items'),
  Table.localOnly('local_lists', [
    Column.text('timestamp'),
    Column.text('name'),
    Column.text('owner')
  ], viewName: 'lists'),
  Table.localOnly('local_items', [
    Column.text('timestamp'),
    Column.text('name'),
    Column.integer('checked'),
    Column.integer('history'),
    Column.text('owner'),
    Column.text('list')
  ], viewName: 'items')
]);