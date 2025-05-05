import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/report.dart';
import '../providers/reports_provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart' as models;
import 'report_dialog.dart';

class ReportsByTypeScreen extends StatelessWidget {
  final ReportType type;

  const ReportsByTypeScreen({super.key, required this.type});

  String _getTypeName(ReportType type) {
    switch (type) {
      case ReportType.daily:
        return 'דוחות יומיים';
      case ReportType.weekly:
        return 'דוחות שבועיים';
      case ReportType.monthly:
        return 'דוחות חודשיים';
      case ReportType.yearly:
        return 'דוחות שנתיים';
      case ReportType.custom:
        return 'דוחות מותאמים';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportsProvider = context.watch<ReportsProvider>();
    final authProvider = context.watch<AuthProvider>();

    final filteredReports = reportsProvider.reports
        .where((report) => report.type == type)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTypeName(type)),
        actions: [
          if (_isAdminOrStaff(authProvider.userRole))
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ReportDialog(
                    report: Report(
                      id: '',
                      userId: authProvider.user?.uid ?? '',
                      title: '',
                      description: '',
                      startDate: DateTime.now(),
                      endDate: DateTime.now(),
                      type: type,
                      createdAt: DateTime.now(),
                      status: ReportStatus.draft,
                      content: ReportContent(text: ''),
                    ),
                  ),
                );
              },
            ),
        ],
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
                        onPressed: () => reportsProvider.fetchReports(),
                        child: const Text('נסה שוב'),
                      ),
                    ],
                  ),
                )
              : filteredReports.isEmpty
                  ? Center(
                      child: Text(
                        'אין דוחות מסוג זה',
                        style: theme.textTheme.titleLarge,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = filteredReports[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            title: Text(report.title ?? 'ללא כותרת'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(report.description ?? 'ללא תיאור'),
                                const SizedBox(height: 8),
                                Text(
                                  'נוצר ב: ${_formatDate(report.createdAt)}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                if (report.startDate != null && report.endDate != null)
                                  Text(
                                    'תקופה: ${_formatDate(report.startDate!)} - ${_formatDate(report.endDate!)}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                              ],
                            ),
                            trailing: _buildReportActions(context, report, authProvider),
                          ),
                        );
                      },
                    ),
    );
  }

  bool _isAdminOrStaff(models.UserRole? role) {
    final effectiveRole = role ?? models.UserRole.user;
    return effectiveRole == models.UserRole.admin || effectiveRole == models.UserRole.staff;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildReportActions(
    BuildContext context,
    Report report,
    AuthProvider authProvider,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: () => context.read<ReportsProvider>().downloadReport(report.id),
        ),
        if (_isAdminOrStaff(authProvider.userRole))
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('ערוך'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('מחק'),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                showDialog(
                  context: context,
                  builder: (context) => ReportDialog(report: report),
                );
              } else if (value == 'delete') {
                _showDeleteConfirmation(context, report);
              }
            },
          ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת דוח'),
        content: Text('האם אתה בטוח שברצונך למחוק את הדוח "${report.title ?? 'ללא כותרת'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () {
              context.read<ReportsProvider>().deleteReport(report.id);
              Navigator.pop(context);
            },
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }
} 