import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart' as models;

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Implement events loading logic
      await Future.delayed(const Duration(seconds: 1)); // Simulated delay
    } catch (e) {
      setState(() {
        _error = 'שגיאה בטעינת האירועים';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.currentUser?.role == models.UserRole.admin;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEvents,
              child: const Text('נסה שוב'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: const Center(
        child: Text('רשימת האירועים תופיע כאן'),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Implement add event functionality
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
} 