import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum UserRole {
  admin,
  staff,
  user,
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? photoURL;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.photoURL,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.toString() == 'UserRole.${map['role']}',
        orElse: () => UserRole.user,
      ),
      photoURL: map['photoURL'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toString().split('.').last,
      'photoURL': photoURL,
    };
  }
}

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _user;
  UserRole? _userRole;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  UserRole? get userRole => _userRole;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user != null
          ? UserModel(
              uid: user.uid,
              name: user.displayName ?? '',
              email: user.email ?? '',
              phone: user.phoneNumber ?? '',
              role: UserRole.values.firstWhere(
                (e) =>
                    e.toString().split('.').last ==
                    user.providerData.first.providerId,
                orElse: () => UserRole.user,
              ),
              photoURL: user.photoURL,
            )
          : null;
      if (user != null) {
        _loadUserRole();
      } else {
        _userRole = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserRole() async {
    if (_user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        final role = doc.data()!['role'] as String;
        _userRole = UserRole.values.firstWhere(
          (e) => e.toString().split('.').last == role,
          orElse: () => UserRole.user,
        );
      } else {
        _userRole = UserRole.user;
      }
      notifyListeners();
    } catch (e) {
      _error = 'שגיאה בטעינת פרטי המשתמש';
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _createSession(result.user!);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithPhone(String phoneNumber) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _error = _getAuthErrorMessage(e);
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          // Handle code sent
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Handle timeout
        },
      );

      return true;
    } catch (e) {
      _error = 'שגיאה בהתחברות עם מספר טלפון';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _userRole = null;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  Future<void> _createSession(User user) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      final connectivity = await Connectivity().checkConnectivity();

      await _firestore.collection('sessions').add({
        'userId': user.uid,
        'deviceInfo': {
          'platform': await _getPlatformInfo(deviceInfo),
          'appVersion': packageInfo.version,
          'buildNumber': packageInfo.buildNumber,
        },
        'connectivity': connectivity.toString(),
        'lastActive': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': FieldValue.serverTimestamp(),
        'isValid': true,
      });
    } catch (e) {
      print('Error creating session: $e');
    }
  }

  Future<Map<String, dynamic>> _getPlatformInfo(
      DeviceInfoPlugin deviceInfo) async {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return {
        'platform': 'android',
        'model': androidInfo.model,
        'version': androidInfo.version.release,
      };
    } else {
      final iosInfo = await deviceInfo.iosInfo;
      return {
        'platform': 'ios',
        'model': iosInfo.model,
        'version': iosInfo.systemVersion,
      };
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'משתמש לא נמצא';
      case 'wrong-password':
        return 'סיסמה שגויה';
      case 'invalid-email':
        return 'כתובת אימייל לא תקינה';
      case 'user-disabled':
        return 'המשתמש הושבת';
      case 'too-many-requests':
        return 'יותר מדי ניסיונות התחברות. נסה שוב מאוחר יותר';
      default:
        return 'שגיאה בהתחברות';
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _user = null;
        notifyListeners();
        return;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _user = UserModel.fromMap(doc.data()!);
      } else {
        _user = UserModel(
          uid: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          phone: user.phoneNumber ?? '',
          role: UserRole.user,
          photoURL: user.photoURL,
        );
      }
      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
      _user = null;
      notifyListeners();
    }
  }

  Future<void> updateUser({
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Update user profile
      await user.updateDisplayName(name);
      await user.updateEmail(email);

      // Update additional user data in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
        'email': email,
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh user data
      await _loadUserData();
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }
}
