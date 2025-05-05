import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/unauthorized_screen.dart';
import '../screens/register_screen.dart';
import '../screens/add_staff_screen.dart';
import '../screens/edit_staff_screen.dart';
import '../screens/groups_screen.dart';
import '../screens/events_screen.dart';
import '../models/user.dart';
import '../screens/create_user_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String settingsRoute = '/settings';
  static const String unauthorized = '/unauthorized';
  static const String register = '/register';
  static const String addStaff = '/add-staff';
  static const String editStaff = '/edit-staff';
  static const String groups = '/groups';
  static const String events = '/events';
  static const String createUser = '/create-user';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case settingsRoute:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case unauthorized:
        return MaterialPageRoute(builder: (_) => const UnauthorizedScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case addStaff:
        return MaterialPageRoute(builder: (_) => const AddStaffScreen());
      case editStaff:
        final staffMember = settings.arguments as User;
        return MaterialPageRoute(
          builder: (_) => EditStaffScreen(staffMember: staffMember),
        );
      case groups:
        return MaterialPageRoute(builder: (_) => const GroupsScreen());
      case events:
        return MaterialPageRoute(builder: (_) => const EventsScreen());
      case createUser:
        return MaterialPageRoute(builder: (_) => const CreateUserScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}

class RouteGuard extends StatelessWidget {
  final Widget child;
  final List<UserRole> allowedRoles;

  const RouteGuard({
    super.key,
    required this.child,
    required this.allowedRoles,
  });

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<UserRole?>();
    
    if (userRole == null || !allowedRoles.contains(userRole)) {
      return const UnauthorizedScreen();
    }

    return child;
  }
}

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> pushNamed(String routeName, {Object? arguments}) async {
    await navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  static Future<void> pushReplacementNamed(
    String routeName, {
    Object? arguments,
  }) async {
    await navigatorKey.currentState?.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  static void pop() {
    navigatorKey.currentState?.pop();
  }

  static Future<void> pushAndRemoveUntil(String routeName) async {
    await navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
  }
}
