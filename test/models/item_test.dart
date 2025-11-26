import 'package:flutter_test/flutter_test.dart';
import 'package:supalist/models/item.dart';

void main() {
  test('Item toMap and fromMap roundtrip', () {
    final timestamp = DateTime.parse('2020-01-01T00:00:00');
    final item = Item(id: 42, name: 'Milk', timestamp: timestamp, checked: true);

    final map = item.toMap();

    expect(map['id'], 42);
    expect(map['name'], 'Milk');
    expect(map['checked'], 1);
    // timestamp is serialized as string and should parse back to the same instant
    final item2 = Item.fromMap(map);

    expect(item2.id, item.id);
    expect(item2.name, item.name);
    expect(item2.checked, item.checked);
    expect(item2.timestamp.millisecondsSinceEpoch, item.timestamp.millisecondsSinceEpoch);
  });
}
