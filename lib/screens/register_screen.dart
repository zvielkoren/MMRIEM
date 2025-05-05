import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../routes/routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'נא להזין שם';
    }
    if (value.length < 2) {
      return 'השם חייב להכיל לפחות 2 תווים';
    }
    return null;
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'נא להזין סיסמה';
    }
    if (value.length < 6) {
      return 'הסיסמה חייבת להכיל לפחות 6 תווים';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'נא לאשר את הסיסמה';
    }
    if (value != _passwordController.text) {
      return 'הסיסמאות אינן תואמות';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      // Create user with email and password
      final userCredential = await authProvider.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Update user profile
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      // Save additional user data to Firestore
      await authProvider.saveUserData(
        userCredential.user!.uid,
        _nameController.text.trim(),
        _emailController.text.trim(),
        _phoneController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(); // Return to login screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error ?? 'שגיאה בהרשמה')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('הרשמה')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/images/logo.png', height: 120),
                const SizedBox(height: 32),
                Text(
                  'הרשמה למערכת',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _nameController,
                  label: 'שם מלא',
                  validator: _validateName,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'אימייל',
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'מספר טלפון',
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  label: 'סיסמה',
                  obscureText: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'אימות סיסמה',
                  obscureText: true,
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  onPressed: _handleRegister,
                  isLoading: authProvider.isLoading,
                  text: 'הרשמה',
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed:
                      () => Navigator.of(
                        context,
                      ).pushReplacementNamed(AppRoutes.login),
                  child: const Text('יש לך כבר חשבון? התחבר עכשיו'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
