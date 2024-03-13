import 'package:supalist/Models/item.dart';

class Supalist{
  final int? id;
  String name;
  bool owner;
  late DateTime timestamp;

  List<Item> items = [];

  Supalist({this.id, required this.name, this.owner=true, timestamp}) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'name': name,
    'id': id,
    'owner': owner ? 1 : 0,
    'timestamp': timestamp.toString(),
  };

  factory Supalist.fromMap(Map<String, dynamic> map) {
    return Supalist(
      name: map['name'],
      id: map['id'],
      owner: map['owner'] == 1 ? true : false,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}