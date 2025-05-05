import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group.dart';

class GroupsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Group> _groups = [];
  bool _isLoading = false;
  String? _error;

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('groups').get();
      _groups = snapshot.docs
          .map((doc) => Group.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      _error = 'שגיאה בטעינת הקבוצות: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createGroup({
    required String name,
    required String description,
  }) async {
    try {
      final group = Group(
        id: '',
        name: name,
        description: description,
        createdAt: DateTime.now(),
        memberIds: [],
      );

      final docRef = await _firestore.collection('groups').add(group.toJson());
      await fetchGroups(); // Refresh the groups list
    } catch (e) {
      _error = 'שגיאה ביצירת הקבוצה: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateGroup(Group group) async {
    try {
      await _firestore.collection('groups').doc(group.id).update(group.toJson());
      await fetchGroups(); // Refresh the groups list
    } catch (e) {
      _error = 'שגיאה בעדכון הקבוצה: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).delete();
      await fetchGroups(); // Refresh the groups list
    } catch (e) {
      _error = 'שגיאה במחיקת הקבוצה: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addMemberToGroup(String groupId, String userId) async {
    try {
      final group = _groups.firstWhere((g) => g.id == groupId);
      final updatedMemberIds = [...group.memberIds, userId];
      
      await _firestore.collection('groups').doc(groupId).update({
        'memberIds': updatedMemberIds,
      });
      
      await fetchGroups(); // Refresh the groups list
    } catch (e) {
      _error = 'שגיאה בהוספת חבר לקבוצה: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    try {
      final group = _groups.firstWhere((g) => g.id == groupId);
      final updatedMemberIds = group.memberIds.where((id) => id != userId).toList();
      
      await _firestore.collection('groups').doc(groupId).update({
        'memberIds': updatedMemberIds,
      });
      
      await fetchGroups(); // Refresh the groups list
    } catch (e) {
      _error = 'שגיאה בהסרת חבר מהקבוצה: $e';
      notifyListeners();
      rethrow;
    }
  }
} 