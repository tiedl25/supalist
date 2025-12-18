import 'package:uuid/uuid.dart';

class AccessRights {
  String id;
  String list;
  String? user;
  String? userEmail;
  DateTime? expirationDate;

  AccessRights({String? id, required this.list, this.user, this.userEmail, DateTime? expirationDate}) : 
    id = id ?? Uuid().v4();

  Map<String, dynamic> toMap() => {
    'id': id,
    'list': list,
    'user': user,
    'userEmail': userEmail,
    'expirationDate': expirationDate?.toIso8601String(),
  };

  factory AccessRights.fromMap(Map<String, dynamic> map) {
    return AccessRights(
      list: map['list'],
      id: map['id'],
      user: map['user'],
      userEmail: map['userEmail'],
      expirationDate: map['expirationDate'] != null ? DateTime.parse(map['expirationDate']) : null,
    );
  }
}