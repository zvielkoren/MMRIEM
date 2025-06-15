import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  // Collection references
  static CollectionReference get users => _firestore.collection('users');
  static CollectionReference get profileRequests =>
      _firestore.collection('profile_requests');
  static CollectionReference get notifications =>
      _firestore.collection('notifications');

  // Helper methods
  static Future<DocumentSnapshot> getUserDocument(String userId) async {
    return await users.doc(userId).get();
  }

  static Future<void> updateUserDocument(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await users.doc(userId).update(data);
  }

  static Future<void> createProfileRequest(Map<String, dynamic> data) async {
    await profileRequests.add(data);
  }

  static Stream<QuerySnapshot> getUserNotifications(String userId) {
    return notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
