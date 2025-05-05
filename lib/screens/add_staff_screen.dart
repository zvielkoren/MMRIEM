import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/staff_provider.dart';
import '../models/user.dart' as models;

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  models.UserRole _selectedRole = models.UserRole.user;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _addStaffMember() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await context.read<StaffProvider>().createStaffMember(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          role: _selectedRole,
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('חבר הצוות נוסף בהצלחה')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('שגיאה בהוספת חבר צוות: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('הוספת חבר צוות'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'אימייל',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'נא להזין אימייל';
                  }
                  if (!value.contains('@')) {
                    return 'נא להזין אימייל תקין';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'סיסמה',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'נא להזין סיסמה';
                  }
                  if (value.length < 6) {
                    return 'הסיסמה חייבת להכיל לפחות 6 תווים';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
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
              ),
              const SizedBox(height: 16),
              TextFormField(
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
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<models.UserRole>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'תפקיד',
                  border: OutlineInputBorder(),
                ),
                items: models.UserRole.values.map((role) {
                  return DropdownMenuItem<models.UserRole>(
                    value: role,
                    child: Text(_getRoleName(role)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRole = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _addStaffMember,
                child: const Text('הוסף חבר צוות'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleName(models.UserRole role) {
    switch (role) {
      case models.UserRole.admin:
        return 'מנהל מערכת';
      case models.UserRole.team:
        return 'צוות';
      case models.UserRole.staff:
        return 'סטף';
      case models.UserRole.group:
        return 'קבוצה';
      case models.UserRole.user:
        return 'משתמש';
    }
  }
} 