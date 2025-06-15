import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/user.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _developerId = 'developer'; // ID של המתכנת
  final String _developerName = 'צביאל קורן'; // שם המתכנת
  List<ChatMessage> _messages = [];
  List<String> _activeChats = []; // רשימת משתמשים שיש להם צ'אט פעיל
  bool _isLoading = false;
  String? _error;
  String? _currentChatUserId; // ID של המשתמש הנוכחי בצ'אט

  List<ChatMessage> get messages => _messages;
  List<String> get activeChats => _activeChats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentChatUserId => _currentChatUserId;

  Future<void> sendMessage(String content, User currentUser) async {
    try {
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: currentUser.id,
        senderName: currentUser.displayName,
        content: content,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('chats')
          .doc(currentUser.id)
          .collection('messages')
          .add(message.toJson());
      await loadMessages(currentUser.id);
    } catch (e) {
      _error = 'שגיאה בשליחת ההודעה: $e';
      notifyListeners();
    }
  }

  Future<void> loadMessages(String userId) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _currentChatUserId = userId;

    try {
      final snapshot =
          await _firestore
              .collection('chats')
              .doc(userId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(50)
              .get();

      _messages =
          snapshot.docs.map((doc) => ChatMessage.fromJson(doc.data())).toList();
    } catch (e) {
      _error = 'שגיאה בטעינת ההודעות: $e';
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> loadActiveChats() async {
    try {
      final snapshot = await _firestore.collection('chats').get();
      _activeChats = snapshot.docs.map((doc) => doc.id).toList();
      notifyListeners();
    } catch (e) {
      _error = 'שגיאה בטעינת רשימת הצ\'אטים: $e';
      notifyListeners();
    }
  }

  Future<void> clearChat(String userId) async {
    try {
      final batch = _firestore.batch();
      final messages =
          await _firestore
              .collection('chats')
              .doc(userId)
              .collection('messages')
              .get();

      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      await loadMessages(userId);
    } catch (e) {
      _error = 'שגיאה במחיקת ההודעות: $e';
      notifyListeners();
    }
  }

  Future<void> sendLogsToDeveloper(
    String userId,
    Map<String, dynamic> logs,
  ) async {
    try {
      await _firestore.collection('chats').doc(userId).collection('logs').add({
        'timestamp': Timestamp.now(),
        'logs': logs,
      });
    } catch (e) {
      _error = 'שגיאה בשליחת הלוגים: $e';
      notifyListeners();
    }
  }

  Stream<List<ChatMessage>> get messagesStream {
    if (_currentChatUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chats')
        .doc(_currentChatUserId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatMessage.fromJson(doc.data()))
                  .toList(),
        );
  }
}
