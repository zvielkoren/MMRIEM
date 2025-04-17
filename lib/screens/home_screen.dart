import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import '../routes/routes.dart';
import '../widgets/custom_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HomeTab(),
    const _StaffTab(),
    const _ReportsTab(),
    const _ProfileTab(),
    const _SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getTitle(_currentIndex),
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.signOut();
              AppRouter.pushAndRemoveUntil(AppRoutes.login);
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_isAllowed(authProvider.userRole, index)) {
            setState(() => _currentIndex = index);
          } else {
            AppRouter.pushNamed(AppRoutes.unauthorized);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'בית',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'צוות',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'דוחות',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'פרופיל',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'הגדרות',
          ),
        ],
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'דף הבית';
      case 1:
        return 'צוות';
      case 2:
        return 'דוחות';
      case 3:
        return 'פרופיל';
      case 4:
        return 'הגדרות';
      default:
        return '';
    }
  }

  bool _isAllowed(UserRole? role, int index) {
    switch (index) {
      case 0: // Home
        return true;
      case 1: // Staff
        return role == UserRole.admin || role == UserRole.staff;
      case 2: // Reports
        return role == UserRole.admin || role == UserRole.staff;
      case 3: // Profile
        return true;
      case 4: // Settings
        return true;
      default:
        return false;
    }
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('דף הבית'),
    );
  }
}

class _StaffTab extends StatelessWidget {
  const _StaffTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('צוות'),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('דוחות'),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('פרופיל'),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('הגדרות'),
    );
  }
}
