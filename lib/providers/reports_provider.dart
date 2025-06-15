import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/report.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import '../models/user.dart';

class ReportsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<Report> _reports = [];
  bool _isLoading = false;
  String? _error;

  List<Report> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchReports({UserRole? userRole, String? userId}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      Query query = _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true);

      // Apply filters based on user role
      if (userRole == UserRole.admin) {
        // Admin can see all reports
        query = query;
      } else if (userRole == UserRole.staff) {
        // Staff can see reports they created or are assigned to
        query = query.where('userId', isEqualTo: userId);
      } else {
        // Other roles can only see their own reports
        query = query.where('userId', isEqualTo: userId);
      }

      final QuerySnapshot snapshot = await query.get();

      _reports = snapshot.docs
          .map((doc) => Report.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'אירעה שגיאה בטעינת הדוחות';
      debugPrint('Error fetching reports: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createReport({
    required String title,
    required String description,
    required ReportType type,
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required ReportContent content,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final newReport = {
        'title': title,
        'description': description,
        'type': type.toString().split('.').last,
        'userId': userId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'content': {
          'text': content.text,
          'attachments': content.attachments,
          'notes': content.notes,
        },
        'status': ReportStatus.draft.toString().split('.').last,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final docRef = await _firestore.collection('reports').add(newReport);
      await docRef.update({'id': docRef.id});

      await fetchReports();
    } catch (e) {
      _error = 'אירעה שגיאה ביצירת הדוח';
      debugPrint('Error creating report: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateReport({
    required String reportId,
    required String title,
    required String description,
    required ReportType type,
    required DateTime startDate,
    required DateTime endDate,
    required ReportContent content,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('reports').doc(reportId).update({
        'title': title,
        'description': description,
        'type': type.toString().split('.').last,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'content': {
          'text': content.text,
          'attachments': content.attachments,
          'notes': content.notes,
        },
        'updatedAt': DateTime.now().toIso8601String(),
      });

      await fetchReports();
    } catch (e) {
      _error = 'אירעה שגיאה בעדכון הדוח';
      debugPrint('Error updating report: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('reports').doc(reportId).delete();
      await fetchReports();
    } catch (e) {
      _error = 'אירעה שגיאה במחיקת הדוח';
      debugPrint('Error deleting report: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> downloadReport(String reportId) async {
    try {
      final reportDoc =
          await _firestore.collection('reports').doc(reportId).get();
      if (!reportDoc.exists) {
        throw Exception('Report not found');
      }

      final reportData = reportDoc.data()!;
      final fileUrl = reportData['fileUrl'] as String?;

      if (fileUrl == null) {
        throw Exception('No file URL found for this report');
      }

      final ref = _storage.refFromURL(fileUrl);
      final bytes = await ref.getData();
      if (bytes == null) {
        throw Exception('Failed to download file');
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(fileUrl);
      final filePath = path.join(tempDir.path, fileName);

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      final fileUri = Uri.file(filePath);
      if (await canLaunch(fileUri.toString())) {
        await launch(fileUri.toString());
      } else {
        throw Exception('Could not launch file');
      }
    } catch (e) {
      throw Exception('Failed to download report: $e');
    }
  }

  Future<void> updateReportStatus(String reportId, ReportStatus status) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('reports').doc(reportId).update({
        'status': status.toString().split('.').last,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      await fetchReports();
    } catch (e) {
      _error = 'אירעה שגיאה בעדכון סטטוס הדוח';
      debugPrint('Error updating report status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getReportTypeText(ReportType type) {
    switch (type) {
      case ReportType.daily:
        return 'יומי';
      case ReportType.weekly:
        return 'שבועי';
      case ReportType.monthly:
        return 'חודשי';
      case ReportType.yearly:
        return 'שנתי';
      case ReportType.custom:
        return 'מותאם';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.draft:
        return 'טיוטה';
      case ReportStatus.submitted:
        return 'הוגש';
      case ReportStatus.reviewed:
        return 'נבדק';
    }
  }
}
