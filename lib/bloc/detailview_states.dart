import 'package:flutter/widgets.dart';
import 'package:supalist/models/supalist.dart';

abstract class DetailViewState {
  final Supalist supalist;
  DetailViewState({required this.supalist});
}

class DetailViewLoading extends DetailViewState {
  DetailViewLoading({required super.supalist});
}

class DetailViewLoaded extends DetailViewState {
  final TextEditingController textController;
  bool addTile;

  DetailViewLoaded({required super.supalist, TextEditingController? textController, this.addTile = false}) : textController = textController ?? TextEditingController();

  DetailViewLoaded copy({Supalist? supalist, TextEditingController? textController, bool? addTile}) {
    return DetailViewLoaded(
        supalist: supalist ?? this.supalist, textController: textController ?? this.textController, addTile: addTile ?? this.addTile);
  }

  factory DetailViewLoaded.fromLoading(state, {bool addTile = false}) {
    return DetailViewLoaded(supalist: state.supalist, addTile: addTile);
  }
}