import 'package:uuid/uuid.dart';

class AccessRights {
  String id;
  String list;
  String user;
  String? userEmail;
  bool fullAccess;
  DateTime? expirationDate;

  AccessRights({String? id, required this.list, required this.user, this.userEmail, this.fullAccess = false, DateTime? expirationDate}) : 
    id = id ?? Uuid().v4(),
    expirationDate = expirationDate ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'list': list,
    'user': user,
    'userEmail': userEmail,
    'fullAccess': fullAccess,
    'expirationDate': expirationDate.toString(),
  };

  factory AccessRights.fromMap(Map<String, dynamic> map) {
    return AccessRights(
      list: map['list'],
      id: map['id'],
      user: map['user'],
      userEmail: map['userEmail'],
      fullAccess: map['fullAccess'],
      expirationDate: DateTime.parse(map['expirationDate']),
    );
  }
}