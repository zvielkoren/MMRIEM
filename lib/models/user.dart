import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin,
  team,
  staff,
  group,
  user,
}

class User {
  final String id;
  final String email;
  final String displayName;
  final String phoneNumber;
  final UserRole role;
  final String? groupId;
  final String? groupName;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? photoURL;

  // Aliases for backward compatibility
  String get uid => id;
  String get name => displayName;
  String get phone => phoneNumber;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.phoneNumber,
    required this.role,
    this.groupId,
    this.groupName,
    required this.createdAt,
    this.lastLoginAt,
    this.photoURL,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.user,
      ),
      groupId: json['groupId'] as String?,
      groupName: json['groupName'] as String?,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? (json['lastLoginAt'] is Timestamp
              ? (json['lastLoginAt'] as Timestamp).toDate()
              : DateTime.parse(json['lastLoginAt'] as String))
          : null,
      photoURL: json['photoURL'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'role': role.toString().split('.').last,
      'groupId': groupId,
      'groupName': groupName,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'photoURL': photoURL,
    };
  }
} 