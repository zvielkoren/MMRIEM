import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/report.dart';
import '../providers/reports_provider.dart';
import '../providers/auth_provider.dart';

class ReportDialog extends StatefulWidget {
  final Report? report;

  const ReportDialog({super.key, this.report});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _textController;
  late ReportType _selectedType;
  String? _selectedUserId;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.report?.content.text);
    _selectedType = widget.report?.type ?? ReportType.daily;
    _selectedUserId = widget.report?.userId;
    _loadUsers();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    // TODO: Implement user loading from Firestore
    setState(() {
      _users = [
        {'id': '1', 'name': 'משתמש 1'},
        {'id': '2', 'name': 'משתמש 2'},
        {'id': '3', 'name': 'משתמש 3'},
      ];
    });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    return AlertDialog(
      title: Text(widget.report == null ? 'דוח חדש' : 'עריכת דוח'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('סוג דוח', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ReportType.values.map((type) {
                  final isSelected = type == _selectedType;
                  return ChoiceChip(
                    label: Text(_getReportTypeText(type)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedType = type);
                      }
                    },
                    backgroundColor: isSelected ? theme.primaryColor : null,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('חניך', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _users.map((user) {
                    final isSelected = user['id'] == _selectedUserId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(user['name']),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedUserId = user['id']);
                          }
                        },
                        backgroundColor: isSelected ? theme.primaryColor : null,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Text('תוכן הדוח', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _textController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'הכנס את תוכן הדוח כאן...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'נא להזין את תוכן הדוח';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              if (widget.report == null) {
                await context.read<ReportsProvider>().createReport(
                  text: _textController.text,
                  type: _selectedType,
                  userId: _selectedUserId,
                  instructorId: authProvider.user?.uid ?? '',
                  status: ReportStatus.draft,
                );
              } else {
                // TODO: Implement report update
              }
              if (mounted) {
                Navigator.pop(context);
              }
            }
          },
          child: Text(widget.report == null ? 'שמור' : 'עדכן'),
        ),
      ],
    );
  }
} 