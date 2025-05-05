import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Event> _events = [];
  bool _isLoading = false;
  String? _error;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadEvents({String? groupId}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      Query query = _firestore.collection('events');
      if (groupId != null) {
        query = query.where('groupId', isEqualTo: groupId);
      }
      query = query.orderBy('startDate', descending: false);

      final QuerySnapshot snapshot = await query.get();

      _events = snapshot.docs
          .map((doc) => Event.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'אירעה שגיאה בטעינת האירועים';
      debugPrint('Error loading events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createEvent(Event event) async {
    try {
      _isLoading = true;
      notifyListeners();

      final docRef = _firestore.collection('events').doc();
      final eventData = {
        ...event.toJson(),
        'id': docRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(eventData);
      await loadEvents(groupId: event.groupId);
    } catch (e) {
      _error = 'אירעה שגיאה ביצירת האירוע';
      debugPrint('Error creating event: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateEvent(Event event) async {
    try {
      _isLoading = true;
      notifyListeners();

      final eventData = {
        ...event.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('events').doc(event.id).update(eventData);
      await loadEvents(groupId: event.groupId);
    } catch (e) {
      _error = 'אירעה שגיאה בעדכון האירוע';
      debugPrint('Error updating event: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('events').doc(eventId).delete();
      _events.removeWhere((event) => event.id == eventId);
    } catch (e) {
      _error = 'אירעה שגיאה במחיקת האירוע';
      debugPrint('Error deleting event: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addParticipant(String eventId, String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('events').doc(eventId).update({
        'participants': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final eventIndex = _events.indexWhere((event) => event.id == eventId);
      if (eventIndex != -1) {
        final event = _events[eventIndex];
        final updatedParticipants = List<String>.from(event.participants)
          ..add(userId);
        _events[eventIndex] = Event(
          id: event.id,
          title: event.title,
          description: event.description,
          startDate: event.startDate,
          endDate: event.endDate,
          location: event.location,
          groupId: event.groupId,
          participants: updatedParticipants,
          createdBy: event.createdBy,
          createdAt: event.createdAt,
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      _error = 'אירעה שגיאה בהוספת משתתף';
      debugPrint('Error adding participant: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeParticipant(String eventId, String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('events').doc(eventId).update({
        'participants': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final eventIndex = _events.indexWhere((event) => event.id == eventId);
      if (eventIndex != -1) {
        final event = _events[eventIndex];
        final updatedParticipants = List<String>.from(event.participants)
          ..remove(userId);
        _events[eventIndex] = Event(
          id: event.id,
          title: event.title,
          description: event.description,
          startDate: event.startDate,
          endDate: event.endDate,
          location: event.location,
          groupId: event.groupId,
          participants: updatedParticipants,
          createdBy: event.createdBy,
          createdAt: event.createdAt,
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      _error = 'אירעה שגיאה בהסרת משתתף';
      debugPrint('Error removing participant: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 