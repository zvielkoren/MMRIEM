import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../routes/routes.dart';
import '../widgets/custom_button.dart';

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  String _getErrorMessage(UserRole? role) {
    switch (role) {
      case UserRole.user:
        return 'אין לך הרשאות לצפות בתוכן זה. נדרשת הרשאת מנהל או צוות.';
      case UserRole.staff:
        return 'אין לך הרשאות לצפות בתוכן זה. נדרשת הרשאת מנהל.';
      case UserRole.admin:
        return 'אין לך הרשאות לצפות בתוכן זה.';
      default:
        return 'אין לך הרשאות לצפות בתוכן זה.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'גישה לא מורשית',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _getErrorMessage(authProvider.userRole),
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CustomButton(
                onPressed: () {
                  AppRouter.pushAndRemoveUntil(AppRoutes.home);
                },
                text: 'חזרה לדף הבית',
              ),
              const SizedBox(height: 16),
              CustomButton(
                onPressed: () {
                  authProvider.signOut();
                  AppRouter.pushAndRemoveUntil(AppRoutes.login);
                },
                text: 'התנתק',
                isOutlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
