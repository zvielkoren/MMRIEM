import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../routes/routes.dart';
import '../models/user.dart';
import '../models/report.dart';
import '../providers/reports_provider.dart';
import '../providers/notification_provider.dart';
import 'report_dialog.dart';
import 'reports_by_type_screen.dart';
import '../providers/staff_provider.dart';
import 'groups_screen.dart';
import 'events_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io' show Platform;
import 'profile_screen.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';

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
      case UserRole.developer:
        return 'מתכנת';
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('הפרופיל עודכן בהצלחה')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('שגיאה בעדכון הפרופיל')));
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
                      leading: const CircleAvatar(child: Icon(Icons.person)),
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
                          : Text(
                              authProvider.user?.phoneNumber ?? 'לא זמין',
                            ),
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
  final int? initialIndex;
  const HomeScreen({super.key, this.initialIndex});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 0;

    // Initialize notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      context.read<NotificationProvider>().fetchNotifications(
            authProvider.userRole,
            authProvider.user?.uid,
          );
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = context.watch<AuthProvider>().user;
    final notificationProvider = context.watch<NotificationProvider>();
    final isDeveloper = currentUser?.role == UserRole.developer;
    final isAdmin = currentUser?.role == UserRole.admin;
    final isTeam = currentUser?.role == UserRole.team;
    final isStaff = currentUser?.role == UserRole.staff;

    final List<Widget> pages = [];
    final List<BottomNavigationBarItem> items = [];

    // Add Home tab for everyone
    pages.add(const _HomeTab());
    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'בית',
    ));

    // Add Staff tab for admin/team/staff
    if (isAdmin || isTeam || isStaff) {
      pages.add(const _StaffTab());
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.people),
        label: 'סגל',
      ));
    }

    // Add Groups tab for admin/team
    if (isAdmin || isTeam) {
      pages.add(const _GroupsTab());
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.group),
        label: 'קבוצות',
      ));
    }

    // Add Reports tab for admin/staff only
    if (isAdmin || isStaff) {
      pages.add(const _ReportsTab());
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.assignment),
        label: 'דוחות',
      ));
    }

    // Add System tab for admin/team
    if (isAdmin || isTeam) {
      pages.add(const _SystemTab());
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'מערכת',
      ));
    }

    // Add Profile tab for everyone
    pages.add(const ProfileScreen());
    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'פרופיל',
    ));

    // Add Chat tab for everyone
    pages.add(const ChatScreen());
    items.add(BottomNavigationBarItem(
      icon: Stack(
        children: [
          const Icon(Icons.chat),
          if (notificationProvider.unreadMessagesCount > 0)
            Positioned(
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(
                  minWidth: 12,
                  minHeight: 12,
                ),
                child: const Center(
                  child: Text(
                    '•',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      label: 'צ\'אט',
    ));

    // Ensure selected index is valid
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getTitle(_selectedIndex),
          style: theme.textTheme.headlineMedium,
        ),
        actions: [
          if (_selectedIndex == 0) ...[
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined),
                  if (notificationProvider.unreadMessagesCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notificationProvider.unreadMessagesCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.notifications);
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.settingsRoute);
              },
            ),
          ],
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: items,
        currentIndex: _selectedIndex,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant,
        onTap: (index) {
          if (index < pages.length) {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  String _getTitle(int index) {
    final currentUser = context.read<AuthProvider>().user;

    if (index == 0) return 'ברוכים הבאים';
    if (index == 1 && _isAllowed(currentUser?.role, 'staff')) return 'סטף';
    if (index == 2 && _isAllowed(currentUser?.role, 'groups')) return 'קבוצות';
    if (index == 3 && _isAllowed(currentUser?.role, 'events')) return 'אירועים';
    if (index == 4 && _isAllowed(currentUser?.role, 'reports')) return 'דוחות';
    if (index == 5) return 'פרופיל';
    if (index == 6 && _isAllowed(currentUser?.role, 'chat')) return 'צ\'אט';
    return '';
  }

  bool _isAllowed(UserRole? role, String section) {
    if (role == null) return false;

    switch (section) {
      case 'staff':
        return role == UserRole.admin ||
            role == UserRole.team ||
            role == UserRole.developer;
      case 'groups':
        return role == UserRole.admin ||
            role == UserRole.team ||
            role == UserRole.developer;
      case 'events':
        return role == UserRole.admin ||
            role == UserRole.team ||
            role == UserRole.developer;
      case 'reports':
        return role == UserRole.admin ||
            role == UserRole.staff ||
            role == UserRole.developer;
      case 'profile':
        return true;
      case 'chat':
        return role == UserRole.admin ||
            role == UserRole.team ||
            role == UserRole.staff ||
            role == UserRole.developer;
      default:
        return false;
    }
  }

  bool _isAdminOrStaff(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return authProvider.userRole == UserRole.admin ||
        authProvider.userRole == UserRole.staff;
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
  @override
  void initState() {
    super.initState();
    // Use post-frame callback to load staff data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStaff();
    });
  }

  Future<void> _loadStaff() async {
    try {
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      await staffProvider.fetchStaff();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('שגיאה בטעינת רשימת הסטף: $e')));
      }
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
    final currentUser = context.watch<AuthProvider>().user;
    final isAdmin = currentUser?.role == UserRole.admin;

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
                leading: const CircleAvatar(child: Icon(Icons.person)),
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
    final theme = Theme.of(context);
    return Card(
      color: color.withOpacity(0.08),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                  semanticLabel: title,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
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
        return Icons.calendar_today_rounded;
      case ReportType.weekly:
        return Icons.calendar_view_week_rounded;
      case ReportType.monthly:
        return Icons.calendar_month_rounded;
      case ReportType.yearly:
        return Icons.calendar_today_rounded;
      case ReportType.custom:
        return Icons.description_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(ReportStatus status) {
    final theme = Theme.of(context);
    switch (status) {
      case ReportStatus.draft:
        return theme.colorScheme.onSurface.withOpacity(0.5);
      case ReportStatus.submitted:
        return theme.colorScheme.primary;
      case ReportStatus.reviewed:
        return theme.colorScheme.tertiary ?? theme.colorScheme.secondary;
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
    showDialog(context: context, builder: (context) => const ReportDialog());
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
      MaterialPageRoute(builder: (context) => ReportsByTypeScreen(type: type)),
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
              if (_isAdminOrStaff(context))
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded),
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
                Icons.calendar_today_rounded,
                theme.colorScheme.primary,
                () => _showReportsByType(context, ReportType.daily),
              ),
              _buildReportCard(
                context,
                'דוח שבועי',
                Icons.calendar_view_week_rounded,
                theme.colorScheme.secondary,
                () => _showReportsByType(context, ReportType.weekly),
              ),
              _buildReportCard(
                context,
                'דוח חודשי',
                Icons.calendar_month_rounded,
                theme.colorScheme.tertiary ?? theme.colorScheme.secondary,
                () => _showReportsByType(context, ReportType.monthly),
              ),
              _buildReportCard(
                context,
                'דוח שנתי',
                Icons.calendar_today_rounded,
                theme.colorScheme.primaryContainer,
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

  bool _isAdminOrStaff(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return authProvider.userRole == UserRole.admin ||
        authProvider.userRole == UserRole.staff;
  }
}

class _SystemTab extends StatelessWidget {
  const _SystemTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('הודעות מערכת', style: theme.textTheme.headlineSmall),
        ),
        Expanded(
          child: Consumer<NotificationProvider>(
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
                            onPressed: () => provider.deleteNotification(
                                  notification.id,
                                ),
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

class _GroupsTab extends StatelessWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Groups Tab'));
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Events Tab'));
  }
}
