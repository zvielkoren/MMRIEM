import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../models/user.dart' as app;

class StaffProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;
  List<app.User> _staff = [];
  bool _isLoading = false;
  String? _error;

  List<app.User> get staff => _staff;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchStaff() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('users').get();
      _staff = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return app.User.fromJson(data);
      }).toList();
    } catch (e) {
      _error = 'שגיאה בטעינת הצוות: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createStaffMember({
    required String email,
    required String password,
    required String displayName,
    required String phoneNumber,
    required app.UserRole role,
    String? groupId,
    String? groupName,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      final user = app.User(
        id: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        phoneNumber: phoneNumber,
        role: role,
        groupId: groupId,
        groupName: groupName,
        createdAt: DateTime.now(),
        lastLoginAt: null,
      );

      await _firestore.collection('users').doc(user.id).set(user.toJson());
      
      // Add user to group if specified
      if (groupId != null) {
        await _firestore.collection('groups').doc(groupId).update({
          'memberIds': FieldValue.arrayUnion([user.id]),
        });
      }

      await fetchStaff(); // Refresh the staff list
    } catch (e) {
      _error = 'שגיאה ביצירת המשתמש: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateStaffMember(app.User user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());
      await fetchStaff(); // Refresh the staff list
    } catch (e) {
      _error = 'שגיאה בעדכון חבר הצוות: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteStaffMember(String userId) async {
    try {
      // Remove user from their group if they belong to one
      final user = _staff.firstWhere((u) => u.id == userId);
      if (user.groupId != null) {
        await _firestore.collection('groups').doc(user.groupId).update({
          'memberIds': FieldValue.arrayRemove([userId]),
        });
      }

      // Delete user document
      await _firestore.collection('users').doc(userId).delete();
      await fetchStaff(); // Refresh the staff list
    } catch (e) {
      _error = 'שגיאה במחיקת חבר הצוות: $e';
      notifyListeners();
      rethrow;
    }
  }
} 