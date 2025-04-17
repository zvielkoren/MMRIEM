import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.updateUser(
        displayName: _nameController.text,
        phoneNumber: _phoneController.text,
      );
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('הפרופיל עודכן בהצלחה')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בעדכון הפרופיל: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('פרופיל'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _updateProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: theme.colorScheme.primary,
                child: user?.photoURL != null
                    ? ClipOval(
                        child: Image.network(
                          user!.photoURL!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        user?.displayName?.substring(0, 1).toUpperCase() ?? '?',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _nameController,
                label: 'שם מלא',
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                label: 'אימייל',
                enabled: false,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                label: 'מספר טלפון',
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              if (_isEditing)
                CustomButton(
                  onPressed: _updateProfile,
                  text: 'שמור שינויים',
                ),
              const SizedBox(height: 16),
              CustomButton(
                onPressed: () {
                  authProvider.signOut();
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
