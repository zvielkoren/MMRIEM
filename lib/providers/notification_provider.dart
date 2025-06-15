import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';
import '../models/user.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Notification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadMessagesCount = 0;
  int _pendingProfileRequests = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Notification> get notifications => _notifications;
  int get unreadMessagesCount => _unreadMessagesCount;
  int get pendingProfileRequests => _pendingProfileRequests;

  Future<void> fetchNotifications(UserRole? userRole, String? userId) async {
    if (userId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final QuerySnapshot notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _notifications = notificationsSnapshot.docs
          .map((doc) => Notification.fromFirestore(doc))
          .toList();

      _unreadMessagesCount = _notifications
          .where((notification) =>
              !notification.isRead &&
              notification.type == NotificationType.message)
          .length;

      if (userRole == UserRole.admin) {
        final profileRequestsSnapshot = await _firestore
            .collection('profileRequests')
            .where('status', isEqualTo: 'pending')
            .get();
        _pendingProfileRequests = profileRequestsSnapshot.size;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        if (_notifications[index].type == NotificationType.message) {
          _unreadMessagesCount = _unreadMessagesCount - 1;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> markProfileRequestAsHandled(String requestId) async {
    try {
      await _firestore
          .collection('profileRequests')
          .doc(requestId)
          .update({'status': 'handled'});

      _pendingProfileRequests--;
      notifyListeners();

      // Create a notification for the user
      final request =
          await _firestore.collection('profileRequests').doc(requestId).get();

      if (request.exists) {
        final data = request.data() as Map<String, dynamic>;
        final userId = data['userId'] as String;

        await createNotification(
          userId: userId,
          title: 'עדכון בקשת פרופיל',
          body: 'בקשתך לעדכון פרופיל טופלה',
          type: NotificationType.profileRequest,
        );
      }
    } catch (e) {
      debugPrint('Error marking profile request as handled: $e');
    }
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
  }) async {
    try {
      final notification = {
        'userId': userId,
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': type.toString().split('.').last,
      };

      final docRef =
          await _firestore.collection('notifications').add(notification);

      // Add the new notification to the local list
      final newNotification = Notification(
        id: docRef.id,
        userId: userId,
        title: title,
        body: body,
        createdAt: DateTime.now(),
        isRead: false,
        type: type,
      );

      _notifications.insert(0, newNotification);

      if (type == NotificationType.message) {
        _unreadMessagesCount++;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  Future<void> sendMessage({
    required String userId,
    required String title,
    required String message,
  }) async {
    await createNotification(
      userId: userId,
      title: title,
      body: message,
      type: NotificationType.message,
    );
  }

  Future<void> deleteAllNotifications() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Delete all notifications from Firestore
      final batch = _firestore.batch();
      for (final notification in _notifications) {
        batch.delete(_firestore.collection('notifications').doc(notification.id));
      }
      await batch.commit();

      // Clear local notifications
      _notifications.clear();
      _unreadMessagesCount = 0;
      _pendingProfileRequests = 0;

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting all notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
