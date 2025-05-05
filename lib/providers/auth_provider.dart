
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  UserRole? _userRole;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  User? get user => _currentUser; // Alias for backward compatibility
  UserRole? get userRole => _userRole;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _auth.authStateChanges().listen((firebase.User? user) async {
      if (user != null) {
        try {
          final doc = await _firestore.collection('users').doc(user.uid).get();
          if (doc.exists) {
            final data = doc.data()!;
            data['id'] = doc.id;
            _currentUser = User.fromJson(data);
            _userRole = _currentUser?.role;
          } else {
            // Create new user document
            final newUser = User(
              id: user.uid,
              email: user.email!,
              displayName: user.displayName ?? '',
              phoneNumber: user.phoneNumber ?? '',
              role: UserRole.user,
              createdAt: DateTime.now(),
              lastLoginAt: DateTime.now(),
            );
            await _firestore.collection('users').doc(user.uid).set(newUser.toJson());
            _currentUser = newUser;
            _userRole = UserRole.user;
          }
        } catch (e) {
          _error = 'שגיאה בטעינת פרטי המשתמש: $e';
        }
      } else {
        _currentUser = null;
        _userRole = null;
      }
      notifyListeners();
    });
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          data['id'] = doc.id;
          _currentUser = User.fromJson(data);
          _userRole = _currentUser?.role;
        } else {
          // Create new user document
          final newUser = User(
            id: userCredential.user!.uid,
            email: userCredential.user!.email!,
            displayName: userCredential.user!.displayName ?? '',
            phoneNumber: userCredential.user!.phoneNumber ?? '',
            role: UserRole.user,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          await _firestore.collection('users').doc(userCredential.user!.uid).set(newUser.toJson());
          _currentUser = newUser;
          _userRole = UserRole.user;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'שגיאה בהתחברות: $e';
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
        verificationCompleted: (firebase.PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (firebase.FirebaseAuthException e) {
          _error = 'שגיאה באימות מספר הטלפון: $e';
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
      _error = 'שגיאה בהתחברות עם מספר טלפון: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      _error = 'שגיאה בהתנתקות: $e';
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String displayName,
    String? phoneNumber,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        if (phoneNumber != null) {
          // Note: Phone number update requires additional verification
          // This is just a placeholder for the actual implementation
          await _firestore.collection('users').doc(user.uid).update({
            'phoneNumber': phoneNumber,
          });
        }

        await _firestore.collection('users').doc(user.uid).update({
          'displayName': displayName,
        });

        _currentUser = User(
          id: user.uid,
          email: user.email!,
          displayName: displayName,
          phoneNumber: phoneNumber ?? _currentUser?.phoneNumber ?? '',
          role: _userRole ?? UserRole.user,
          createdAt: _currentUser?.createdAt ?? DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
      }
    } catch (e) {
      _error = 'שגיאה בעדכון הפרופיל: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<firebase.UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      _error = 'שגיאה ביצירת משתמש: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveUserData(
    String uid,
    String name,
    String email,
    String phone,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _error = 'שגיאה בשמירת פרטי המשתמש: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser({
    required String displayName,
    required String phoneNumber,
    String? photoURL,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_currentUser == null) {
        throw Exception('לא נמצא משתמש מחובר');
      }

      // Update Firebase Auth user
      await _auth.currentUser?.updateDisplayName(displayName);
      // Note: Phone number update requires additional verification
      // We'll only update it in Firestore for now
      if (photoURL != null) {
        await _auth.currentUser?.updatePhotoURL(photoURL);
      }

      // Update Firestore user document
      final userData = {
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        if (photoURL != null) 'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .update(userData);

      // Update local user object
      _currentUser = User(
        id: _currentUser!.id,
        email: _currentUser!.email,
        displayName: displayName,
        phoneNumber: phoneNumber,
        role: _currentUser!.role,
        groupId: _currentUser!.groupId,
        groupName: _currentUser!.groupName,
        createdAt: _currentUser!.createdAt,
        lastLoginAt: _currentUser!.lastLoginAt,
        photoURL: photoURL ?? _currentUser!.photoURL,
      );

      _error = null;
    } catch (e) {
      _error = 'שגיאה בעדכון המשתמש: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
