class Item{
  final int? id;
  String name;
  late DateTime timestamp;
  bool checked;

  Item({this.id, required this.name, timestamp, this.checked = false}) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'name': name,
    'id': id,
    'timestamp': timestamp.toString(),
    'checked': checked ? 1 : 0
  };

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      name: map['name'],
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      checked: map['checked'] == 1 ? true : false
    );
  }
}