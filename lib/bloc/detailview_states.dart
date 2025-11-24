import 'package:supalist/models/supalist.dart';

abstract class DetailViewState {
  final Supalist supalist;
  DetailViewState({required this.supalist});
}

class DetailViewLoading extends DetailViewState {
  DetailViewLoading({required super.supalist});
}

class DetailViewLoaded extends DetailViewState {
  bool addTile;

  DetailViewLoaded({required super.supalist, this.addTile = false});

  DetailViewLoaded copy({Supalist? supalist, bool? addTile}) {
    return DetailViewLoaded(
        supalist: supalist ?? this.supalist, addTile: addTile ?? this.addTile);
  }

  factory DetailViewLoaded.fromLoading(state, {bool addTile = false}) {
    return DetailViewLoaded(supalist: state.supalist, addTile: addTile);
  }
}