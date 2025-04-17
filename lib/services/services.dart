import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<User?> signInWithPhone(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw _handleAuthException(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          // Handle code sent
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Handle timeout
        },
      );
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('משתמש לא נמצא');
      case 'wrong-password':
        return Exception('סיסמה שגויה');
      case 'invalid-email':
        return Exception('כתובת אימייל לא תקינה');
      case 'user-disabled':
        return Exception('המשתמש הושבת');
      case 'too-many-requests':
        return Exception('יותר מדי ניסיונות התחברות. נסה שוב מאוחר יותר');
      default:
        return Exception('שגיאה בהתחברות');
    }
  }
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return User.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('שגיאה בטעינת פרטי המשתמש');
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.toFirestore());
    } catch (e) {
      throw Exception('שגיאה בעדכון פרטי המשתמש');
    }
  }

  Future<void> createSession(Session session) async {
    try {
      await _firestore
          .collection('sessions')
          .doc(session.id)
          .set(session.toFirestore());
    } catch (e) {
      throw Exception('שגיאה ביצירת סשן');
    }
  }
}

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImage(String userId, String filePath) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId');
      final uploadTask = await ref.putFile(File(filePath));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('שגיאה בהעלאת תמונה');
    }
  }

  Future<void> deleteProfileImage(String userId) async {
    try {
      await _storage.ref().child('profile_images/$userId').delete();
    } catch (e) {
      throw Exception('שגיאה במחיקת תמונה');
    }
  }
}

class MessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      throw Exception('שגיאה בקבלת טוקן');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      throw Exception('שגיאה בהרשמה לנושא');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      throw Exception('שגיאה בביטול הרשמה לנושא');
    }
  }
}
