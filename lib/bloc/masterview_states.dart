import 'package:supalist/models/supalist.dart';

abstract class MasterViewState {}

class MasterViewLoading extends MasterViewState {}

class MasterViewLoaded extends MasterViewState {
  final List<Supalist> supalists;

  MasterViewLoaded({required this.supalists});
}