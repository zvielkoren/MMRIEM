import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/report.dart';
import '../providers/reports_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsByTypeScreen extends StatelessWidget {
  final ReportType type;

  const ReportsByTypeScreen({super.key, required this.type});

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

  bool _canManageReport(
      UserRole? userRole, String reportUserId, String currentUserId) {
    if (userRole == null) return false;

    switch (userRole) {
      case UserRole.admin:
      case UserRole.developer:
        return true;
      case UserRole.team:
        return true;
      case UserRole.staff:
        return reportUserId == currentUserId;
      default:
        return false;
    }
  }

  bool _canViewReport(
      UserRole? userRole, String reportUserId, String currentUserId) {
    if (userRole == null) return false;

    switch (userRole) {
      case UserRole.admin:
      case UserRole.developer:
      case UserRole.team:
        return true;
      case UserRole.staff:
        return reportUserId == currentUserId;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportsProvider = context.watch<ReportsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUser = context.watch<AuthProvider>().user;

    if (currentUser == null) {
      return const Center(child: Text('יש להתחבר כדי לצפות בדוחות'));
    }

    final canViewReports = currentUser.role == UserRole.admin ||
        currentUser.role == UserRole.developer ||
        currentUser.role == UserRole.team ||
        currentUser.role == UserRole.staff;

    if (!canViewReports) {
      return const Center(child: Text('אין לך הרשאות לצפות בדוחות'));
    }

    final filteredReports =
        reportsProvider.reports.where((report) => report.type == type).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('דוחות ${_getReportTypeText(type)}'),
      ),
      body: reportsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportsProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('שגיאה: ${reportsProvider.error}'),
                      ElevatedButton(
                        onPressed: () => reportsProvider.fetchReports(
                          userRole: authProvider.userRole,
                          userId: authProvider.user?.uid,
                        ),
                        child: const Text('נסה שוב'),
                      ),
                    ],
                  ),
                )
              : filteredReports.isEmpty
                  ? Center(
                      child: Text(
                        'אין דוחות להצגה',
                        style: theme.textTheme.titleLarge,
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('reports')
                          .where('type', isEqualTo: type.name)
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('שגיאה: ${snapshot.error}'));
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final reports = snapshot.data?.docs
                                .where((doc) => _canViewReport(
                                      currentUser.role,
                                      (doc.data()
                                              as Map<String, dynamic>)['userId']
                                          as String,
                                      currentUser.uid,
                                    ))
                                .toList() ??
                            [];

                        if (reports.isEmpty) {
                          return const Center(child: Text('אין דוחות להצגה'));
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: reports.length,
                          itemBuilder: (context, index) {
                            final report =
                                reports[index].data() as Map<String, dynamic>;
                            final reportId = reports[index].id;
                            final canManage = _canManageReport(
                              currentUser.role,
                              report['userId'] as String,
                              currentUser.uid,
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ListTile(
                                title: Text(report['title'] ?? 'דוח ללא כותרת'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'נוצר על ידי: ${report['userName'] ?? 'לא ידוע'}'),
                                    Text(
                                      'תאריך: ${(report['createdAt'] as Timestamp).toDate().toString()}',
                                    ),
                                    Text(
                                        'סטטוס: ${_getStatusText(report['status'] as String)}'),
                                  ],
                                ),
                                trailing: canManage
                                    ? PopupMenuButton(
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit),
                                                SizedBox(width: 8),
                                                Text('ערוך'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete),
                                                SizedBox(width: 8),
                                                Text('מחק'),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) async {
                                          switch (value) {
                                            case 'edit':
                                              // TODO: Implement edit
                                              break;
                                            case 'delete':
                                              final confirmed =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title:
                                                      const Text('מחיקת דוח'),
                                                  content: const Text(
                                                    'האם אתה בטוח שברצונך למחוק את הדוח?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child:
                                                          const Text('ביטול'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      child: const Text('מחק'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirmed == true) {
                                                await FirebaseFirestore.instance
                                                    .collection('reports')
                                                    .doc(reportId)
                                                    .delete();
                                              }
                                              break;
                                          }
                                        },
                                      )
                                    : null,
                              ),
                            );
                          },
                        );
                      },
                    ),
      floatingActionButton: currentUser.role == UserRole.staff ||
              currentUser.role == UserRole.admin ||
              currentUser.role == UserRole.developer
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Implement create new report
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'draft':
        return 'טיוטה';
      case 'submitted':
        return 'הוגש';
      case 'reviewed':
        return 'נבדק';
      default:
        return 'לא ידוע';
    }
  }
}
