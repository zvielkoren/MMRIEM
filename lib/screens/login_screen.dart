import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../routes/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEmailLogin = true;
  bool _isVerifying = false;
  String? _verificationId;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'נא להזין אימייל';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'נא להזין כתובת אימייל תקינה';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'נא להזין מספר טלפון';
    }
    if (!RegExp(r'^05\d{8}$').hasMatch(value)) {
      return 'נא להזין מספר טלפון תקין (05X-XXX-XXXX)';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success;

    if (_isEmailLogin) {
      success = await authProvider.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      success = await authProvider.signInWithPhone(_phoneController.text);
      if (success) {
        setState(() => _isVerifying = true);
      }
    }

    if (!success && mounted) {
      final errorMessage = authProvider.error ?? 'שגיאה בהתחברות';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', height: 120),
                const SizedBox(height: 32),
                Text('ברוכים הבאים', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 16),
                Text('התחבר למערכת', style: theme.textTheme.titleMedium),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLoginMethodButton(
                      'אימייל',
                      _isEmailLogin,
                      () => setState(() => _isEmailLogin = true),
                    ),
                    const SizedBox(width: 16),
                    _buildLoginMethodButton(
                      'טלפון',
                      !_isEmailLogin,
                      () => setState(() => _isEmailLogin = false),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_isEmailLogin) ...[
                  CustomTextField(
                    controller: _emailController,
                    label: 'אימייל',
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'סיסמה',
                    obscureText: true,
                  ),
                ] else ...[
                  CustomTextField(
                    controller: _phoneController,
                    label: 'מספר טלפון',
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                  ),
                ],
                const SizedBox(height: 24),
                CustomButton(
                  onPressed: _handleLogin,
                  isLoading: authProvider.isLoading,
                  text: 'התחבר',
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed:
                      () => Navigator.of(context).pushNamed(AppRoutes.register),
                  child: const Text('עדיין אין לך חשבון? הירשם עכשיו'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginMethodButton(
    String text,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
        foregroundColor:
            isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
      ),
      child: Text(text),
    );
  }
}
