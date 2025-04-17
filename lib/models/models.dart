import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin,
  staff,
  user,
}

class User {
  final String id;
  final String email;
  final String? phoneNumber;
  final String? displayName;
  final String? photoURL;
  final UserRole role;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  User({
    required this.id,
    required this.email,
    this.phoneNumber,
    this.displayName,
    this.photoURL,
    required this.role,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory User.fromFirestore(Map<String, dynamic> data, String id) {
    return User(
      id: id,
      email: data['email'] as String,
      phoneNumber: data['phoneNumber'] as String?,
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == data['role'],
        orElse: () => UserRole.user,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role.toString().split('.').last,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
    };
  }
}

class Session {
  final String id;
  final String userId;
  final Map<String, dynamic> deviceInfo;
  final String connectivity;
  final DateTime lastActive;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isValid;

  Session({
    required this.id,
    required this.userId,
    required this.deviceInfo,
    required this.connectivity,
    required this.lastActive,
    required this.createdAt,
    required this.expiresAt,
    required this.isValid,
  });

  factory Session.fromFirestore(Map<String, dynamic> data, String id) {
    return Session(
      id: id,
      userId: data['userId'] as String,
      deviceInfo: data['deviceInfo'] as Map<String, dynamic>,
      connectivity: data['connectivity'] as String,
      lastActive: (data['lastActive'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      isValid: data['isValid'] as bool,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'deviceInfo': deviceInfo,
      'connectivity': connectivity,
      'lastActive': lastActive,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'isValid': isValid,
    };
  }
}
