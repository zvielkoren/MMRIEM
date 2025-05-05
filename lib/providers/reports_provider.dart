import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import 'dart:io' as io;
import 'dart:convert';

class ReportsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Report> _reports = [];
  bool _isLoading = false;
  String? _error;

  List<Report> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchReports() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final QuerySnapshot snapshot = await _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .get();

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
    required String text,
    required ReportType type,
    String? userId,
    required String instructorId,
    required ReportStatus status,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final newReport = {
        'userId': userId,
        'instructorId': instructorId,
        'type': type.toString().split('.').last,
        'content': {
          'text': text,
          'attachments': [],
          'notes': '',
        },
        'status': status.toString().split('.').last,
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

  Future<void> updateReportStatus(String reportId, ReportStatus newStatus) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('reports').doc(reportId).update({
        'status': newStatus.toString().split('.').last,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      await fetchReports();
    } catch (e) {
      _error = 'אירעה שגיאה בעדכון הסטטוס';
      debugPrint('Error updating report status: $e');
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
      _isLoading = true;
      notifyListeners();

      // Get the report data
      final reportDoc = await _firestore.collection('reports').doc(reportId).get();
      if (!reportDoc.exists) {
        throw Exception('הדוח לא נמצא');
      }

      final report = Report.fromJson(reportDoc.data() as Map<String, dynamic>);

      // Create PDF content
      final pdfContent = '''
דוח ${_getReportTypeText(report.type)}
----------------------------
חניך: ${report.userId ?? 'לא צוין'}
תאריך יצירה: ${_formatDate(report.createdAt)}
סטטוס: ${_getStatusText(report.status)}

תוכן הדוח:
${report.content.text}

${report.content.notes != null ? 'הערות: ${report.content.notes}' : ''}
''';

      // Download the file
      if (kIsWeb) {
        // For web platform
        final bytes = utf8.encode(pdfContent);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'דוח_${report.type}_${_formatDate(report.createdAt)}.txt')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // For mobile platforms
        final directory = await getApplicationDocumentsDirectory();
        final file = io.File('${directory.path}/דוח_${report.type}_${_formatDate(report.createdAt)}.txt');
        await file.writeAsString(pdfContent);
        
        if (await canLaunch(file.path)) {
          await launch(file.path);
        }
      }

      _error = null;
    } catch (e) {
      _error = 'אירעה שגיאה בהורדת הדוח';
      debugPrint('Error downloading report: $e');
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
