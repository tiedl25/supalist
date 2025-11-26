import 'package:flutter_test/flutter_test.dart';
import 'package:supalist/models/supalist.dart';

void main() {
  test('Supalist toMap and fromMap roundtrip', () {
    final timestamp = DateTime.parse('2020-02-02T12:34:56');
    final s = Supalist(id: 7, name: 'Groceries', owner: false, timestamp: timestamp);

    final map = s.toMap();

    expect(map['id'], 7);
    expect(map['name'], 'Groceries');
    expect(map['owner'], 0);

    final s2 = Supalist.fromMap(map);
    expect(s2.id, s.id);
    expect(s2.name, s.name);
    expect(s2.owner, s.owner);
    expect(s2.timestamp.millisecondsSinceEpoch, s.timestamp.millisecondsSinceEpoch);
  });
}
