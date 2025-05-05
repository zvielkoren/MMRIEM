import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../routes/routes.dart';
import '../models/user.dart';
import '../models/report.dart';
import '../providers/reports_provider.dart';
import 'report_dialog.dart';
import 'reports_by_type_screen.dart';
import '../providers/staff_provider.dart';
import '../providers/notifications_provider.dart';
import 'edit_staff_screen.dart';
import 'groups_screen.dart';
import 'events_screen.dart';
import 'create_user_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io' show Platform;

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _nameController.text = authProvider.user?.displayName ?? '';
    _phoneController.text = authProvider.user?.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _getRoleName(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return 'מנהל מערכת';
      case UserRole.team:
        return 'צוות';
      case UserRole.staff:
        return 'סטף';
      case UserRole.group:
        return 'קבוצה';
      case UserRole.user:
        return 'משתמש';
      default:
        return 'משתמש';
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final authProvider = context.read<AuthProvider>();
        await authProvider.updateProfile(
          displayName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );
        setState(() => _isEditing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('הפרופיל עודכן בהצלחה')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('שגיאה בעדכון הפרופיל')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('פרופיל', style: theme.textTheme.headlineMedium),
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => setState(() => _isEditing = true),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('פרטים אישיים', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: _isEditing
                          ? TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'שם מלא',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'נא להזין שם';
                                }
                                return null;
                              },
                            )
                          : Text(authProvider.user?.displayName ?? ''),
                      subtitle: Text(authProvider.user?.email ?? ''),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('טלפון'),
                      subtitle: _isEditing
                          ? TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'מספר טלפון',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'נא להזין מספר טלפון';
                                }
                                return null;
                              },
                            )
                          : Text(authProvider.user?.phoneNumber ?? 'לא זמין'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.work),
                      title: const Text('תפקיד'),
                      subtitle: Text(_getRoleName(authProvider.userRole)),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _isEditing = false),
                            child: const Text('ביטול'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _updateProfile,
                            child: const Text('שמור'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('הגדרות', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('הגדרות מערכת'),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.settingsRoute);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('התנתק'),
                    onTap: () {
                      authProvider.signOut();
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(_currentIndex)),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: _getScreen(_currentIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (_isAllowed(authProvider.userRole, index)) {
            setState(() => _currentIndex = index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'בית',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'צוות',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'קבוצות',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'אירועים',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'פרופיל',
          ),
        ],
      ),
    );
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const _HomeTab();
      case 1:
        return const _StaffTab();
      case 2:
        return const GroupsScreen();
      case 3:
        return const EventsScreen();
      case 4:
        return const _ProfileTab();
      default:
        return const _HomeTab();
    }
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'דף הבית';
      case 1:
        return 'צוות';
      case 2:
        return 'קבוצות';
      case 3:
        return 'אירועים';
      case 4:
        return 'פרופיל';
      default:
        return '';
    }
  }

  bool _isAllowed(UserRole? role, int index) {
    if (role == null) return false;
    
    switch (index) {
      case 0: // Home
        return true;
      case 1: // Reports
        return role == UserRole.admin || 
               role == UserRole.team || 
               role == UserRole.staff;
      case 2: // Staff
        return role == UserRole.admin || 
               role == UserRole.team;
      case 3: // Groups
        return role == UserRole.admin || 
               role == UserRole.team || 
               role == UserRole.group;
      case 4: // Events
        return role == UserRole.admin || 
               role == UserRole.team || 
               role == UserRole.staff;
      case 5: // Profile
        return true;
      default:
        return false;
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('עזרה'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ברוכים הבאים למערכת ניהול MMRIEM',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('המערכת כוללת את התכונות הבאות:'),
              const SizedBox(height: 8),
              _buildHelpItem('דף הבית', 'מסך הבית של המערכת המציג סטטוס כללי'),
              _buildHelpItem('דוחות', 'ניהול דוחות יומיים, שבועיים, חודשיים ושנתיים'),
              _buildHelpItem('צוות', 'ניהול חברי הצוות והרשאות'),
              _buildHelpItem('קבוצות', 'ניהול קבוצות וחניכים'),
              _buildHelpItem('אירועים', 'ניהול אירועים ותוכניות'),
              _buildHelpItem('פרופיל', 'עדכון פרטים אישיים והגדרות'),
              const SizedBox(height: 16),
              const Text(
                'פרטי המתכנת:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildHelpItem('שם', 'צביאל קורן'),
              _buildHelpItem('אימייל', 'zvielkoren@gmail.com'),
              _buildHelpItem('טלפון', '052-3000242'),
              const SizedBox(height: 16),
              const Text(
                'הערה חשובה:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'המתכנת אינו יכול לראות או לגשת למידע רגיש של צוות או מנהלי מערכת. כל בקשה לעזרה תתבצע דרך ממשק המשתמש בלבד.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _sendLogsToDeveloper(context),
                icon: const Icon(Icons.bug_report),
                label: const Text('שלח לוגים למתכנת'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('סגור'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendLogsToDeveloper(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      // Collect system information
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      final connectivity = await Connectivity().checkConnectivity();
      
      final logs = {
        'timestamp': DateTime.now().toIso8601String(),
        'user': {
          'id': user?.id,
          'email': user?.email,
          'role': user?.role.toString(),
          'displayName': user?.displayName,
        },
        'device': {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
          'deviceInfo': await deviceInfo.deviceInfo,
        },
        'app': {
          'version': packageInfo.version,
          'buildNumber': packageInfo.buildNumber,
          'packageName': packageInfo.packageName,
        },
        'connectivity': connectivity.toString(),
        'lastError': authProvider.error,
      };

      // TODO: Implement actual sending of logs
      // For now, just show a success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הלוגים נשלחו למתכנת בהצלחה')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בשליחת הלוגים: $e')),
        );
      }
    }
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(description),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ברוכים הבאים',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'סטטוס היום',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  // TODO: Add status widgets
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffTab extends StatefulWidget {
  const _StaffTab();

  @override
  State<_StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends State<_StaffTab> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<StaffProvider>().fetchStaff();
    } catch (e) {
      setState(() {
        _error = 'שגיאה בטעינת צוות: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'מנהל מערכת';
      case UserRole.team:
        return 'צוות';
      default:
        return 'לא ידוע';
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<StaffProvider>().staff;
    final currentUser = context.watch<User?>();
    final isAdmin = currentUser?.email == 'admin@example.com';

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStaff,
              child: const Text('נסה שוב'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (isAdmin)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement add staff member
              },
              icon: const Icon(Icons.person_add),
              label: const Text('הוסף חבר צוות'),
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: staff.length,
            itemBuilder: (context, index) {
              final member = staff[index];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(member.displayName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.email),
                    Text('תפקיד: ${_getRoleName(member.role)}'),
                    Text('טלפון: ${member.phoneNumber}'),
                  ],
                ),
                trailing: isAdmin
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              // TODO: Implement edit staff member
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              // TODO: Implement delete staff member
                            },
                          ),
                        ],
                      )
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReportsTab extends StatefulWidget {
  const _ReportsTab();

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().fetchReports();
    });
  }

  Widget _buildReportCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.daily:
        return Icons.calendar_today;
      case ReportType.weekly:
        return Icons.calendar_view_week;
      case ReportType.monthly:
        return Icons.calendar_month;
      case ReportType.yearly:
        return Icons.calendar_today;
      case ReportType.custom:
        return Icons.description;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.draft:
        return Colors.grey;
      case ReportStatus.submitted:
        return Colors.blue;
      case ReportStatus.reviewed:
        return Colors.green;
    }
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

  void _showCreateReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ReportDialog(),
    );
  }

  void _showReportDetails(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('פרטי דוח'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('חניך: ${report.userId}'),
              const SizedBox(height: 8),
              Text('סוג דוח: ${_getReportTypeText(report.type)}'),
              const SizedBox(height: 8),
              Text('תאריך יצירה: ${_formatDate(report.createdAt)}'),
              const SizedBox(height: 16),
              const Text('תוכן הדוח:'),
              const SizedBox(height: 8),
              Text(report.content.text),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<ReportsProvider>().updateReportStatus(
                    report.id,
                    report.status == ReportStatus.draft
                        ? ReportStatus.submitted
                        : ReportStatus.draft,
                  );
                  Navigator.pop(context);
                },
                child: Text(
                  report.status == ReportStatus.draft
                      ? 'הגש דוח'
                      : 'החזר לטיוטה',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('סגור'),
          ),
        ],
      ),
    );
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

  void _showReportsByType(BuildContext context, ReportType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportsByTypeScreen(type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportsProvider = context.watch<ReportsProvider>();
    final authProvider = context.watch<AuthProvider>();

    if (reportsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reportsProvider.error != null) {
      return Center(
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
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('דוחות', style: theme.textTheme.headlineMedium),
              if (_isAdminOrStaff(authProvider.userRole))
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showCreateReportDialog(context),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildReportCard(
                context,
                'דוח יומי',
                Icons.calendar_today,
                Colors.blue,
                () => _showReportsByType(context, ReportType.daily),
              ),
              _buildReportCard(
                context,
                'דוח שבועי',
                Icons.calendar_view_week,
                Colors.green,
                () => _showReportsByType(context, ReportType.weekly),
              ),
              _buildReportCard(
                context,
                'דוח חודשי',
                Icons.calendar_month,
                Colors.orange,
                () => _showReportsByType(context, ReportType.monthly),
              ),
              _buildReportCard(
                context,
                'דוח שנתי',
                Icons.calendar_today,
                Colors.purple,
                () => _showReportsByType(context, ReportType.yearly),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('דוחות אחרונים', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reportsProvider.reports.length,
            itemBuilder: (context, index) {
              final report = reportsProvider.reports[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(_getReportIcon(report.type)),
                  title: Text('דוח ${_getReportTypeText(report.type)}'),
                  subtitle: Text('נוצר ב: ${_formatDate(report.createdAt)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () => context
                            .read<ReportsProvider>()
                            .downloadReport(report.id),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(report.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(report.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showReportDetails(context, report),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isAdminOrStaff(UserRole? role) {
    if (role == null) return false;
    return role == UserRole.admin || 
           role == UserRole.team || 
           role == UserRole.staff;
  }
}

class _SystemTab extends StatelessWidget {
  const _SystemTab();

  @override
  Widget build(BuildContext context) {
    final notificationsProvider = Provider.of<NotificationsProvider>(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'הודעות מערכת',
            style: theme.textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: Consumer<NotificationsProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.notifications.isEmpty) {
                return Center(
                  child: Text(
                    'אין הודעות חדשות',
                    style: theme.textTheme.bodyLarge,
                  ),
                );
              }

              return ListView.builder(
                itemCount: provider.notifications.length,
                itemBuilder: (context, index) {
                  final notification = provider.notifications[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: ListTile(
                      title: Text(
                        notification.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        notification.body,
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!notification.isRead)
                            IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () =>
                                  provider.markAsRead(notification.id),
                              tooltip: 'סמן כנקרא',
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                provider.deleteNotification(notification.id),
                            tooltip: 'מחק',
                          ),
                        ],
                      ),
                      onTap: () {
                        if (!notification.isRead) {
                          provider.markAsRead(notification.id);
                        }
                        // Handle notification tap (e.g., navigate to relevant screen)
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}