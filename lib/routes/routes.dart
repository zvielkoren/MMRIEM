import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/unauthorized_screen.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String unauthorized = '/unauthorized';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case unauthorized:
        return MaterialPageRoute(builder: (_) => const UnauthorizedScreen());
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

class AuthGuard extends StatelessWidget {
  final Widget child;
  final List<UserRole> allowedRoles;

  const AuthGuard({
    super.key,
    required this.child,
    required this.allowedRoles,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.user == null) {
      return const LoginScreen();
    }

    if (!allowedRoles.contains(authProvider.userRole)) {
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

  static Future<void> pushReplacementNamed(String routeName,
      {Object? arguments}) async {
    await navigatorKey.currentState
        ?.pushReplacementNamed(routeName, arguments: arguments);
  }

  static void pop() {
    navigatorKey.currentState?.pop();
  }

  static Future<void> pushAndRemoveUntil(String routeName) async {
    await navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => _getScreen(routeName)),
      (route) => false,
    );
  }

  static Widget _getScreen(String routeName) {
    switch (routeName) {
      case AppRoutes.login:
        return const LoginScreen();
      case AppRoutes.home:
        return const HomeScreen();
      case AppRoutes.profile:
        return const ProfileScreen();
      case AppRoutes.settings:
        return const SettingsScreen();
      case AppRoutes.unauthorized:
        return const UnauthorizedScreen();
      default:
        return const Scaffold(
          body: Center(
            child: Text('Route not found'),
          ),
        );
    }
  }
}
