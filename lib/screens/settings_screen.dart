import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('הגדרות'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: const Text('מצב כהה'),
            trailing: Switch(
              value: themeProvider.isDark,
              onChanged: (value) => themeProvider.toggleTheme(),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            onPressed: () {
              authProvider.signOut();
            },
            text: 'התנתק',
            isOutlined: true,
          ),
        ],
      ),
    );
  }
}
