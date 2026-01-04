import 'package:uuid/uuid.dart';

class Item{
  final String id;
  String name;
  late DateTime timestamp;
  bool checked;
  bool history;
  String? owner;
  final String? list;

  Item({String? id, required this.name, timestamp, this.checked = false, this.history = false, required this.owner, this.list}) : 
    id = id ?? Uuid().v4(),
    timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'timestamp': timestamp.toString(),
    'checked': checked ? 1 : 0,
    'history': history ? 1 : 0,
    'owner': owner,
    'list': list,
  };

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      name: map['name'],
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      checked: map['checked'] == 1 ? true : false,
      history: map['history'] == 1 ? true : false,
      owner: map['owner'],
      list: map['list'],
    );
  }
}