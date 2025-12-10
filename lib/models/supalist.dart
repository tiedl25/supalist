import 'package:supalist/models/item.dart';
import 'package:uuid/uuid.dart';

class Supalist{
  String id;
  String name;
  String? owner;
  late DateTime timestamp;

  List<Item> items = [];

  Supalist({String? id, required this.name, required this.owner, timestamp}) : 
    id = id ?? Uuid().v4(),
    timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'owner': owner,
    'timestamp': timestamp.toString(),
  };

  factory Supalist.fromMap(Map<String, dynamic> map) {
    return Supalist(
      name: map['name'],
      id: map['id'],
      owner: map['owner'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}