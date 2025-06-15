import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/staff_provider.dart';
import '../models/user.dart' as models;

class EditStaffScreen extends StatefulWidget {
  final models.User staffMember;

  const EditStaffScreen({super.key, required this.staffMember});

  @override
  State<EditStaffScreen> createState() => _EditStaffScreenState();
}

class _EditStaffScreenState extends State<EditStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late models.UserRole _selectedRole;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.staffMember.displayName,
    );
    _phoneController = TextEditingController(
      text: widget.staffMember.phoneNumber,
    );
    _selectedRole = widget.staffMember.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateStaffMember() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final updatedUser = models.User(
          id: widget.staffMember.id,
          email: widget.staffMember.email,
          displayName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          role: _selectedRole,
          groupId: widget.staffMember.groupId,
          groupName: widget.staffMember.groupName,
          createdAt: widget.staffMember.createdAt,
          lastLoginAt: widget.staffMember.lastLoginAt,
        );

        await context.read<StaffProvider>().updateStaffMember(updatedUser);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('המשתמש עודכן בהצלחה')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('שגיאה בעדכון המשתמש: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('עריכת משתמש')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                items:
                    models.UserRole.values.map((role) {
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
                onPressed: _updateStaffMember,
                child: const Text('עדכן משתמש'),
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
      case models.UserRole.developer:
        return 'מתכנת';
      default:
        return 'לא ידוע';
    }
  }
}
