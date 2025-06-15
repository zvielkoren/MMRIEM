import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../models/user.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final user = authProvider.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('פרופיל', style: theme.textTheme.headlineMedium),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // Navigate to profile tab in home screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                      settings: const RouteSettings(
                        name: '/home',
                        arguments: {'initialIndex': 4}, // Profile tab index
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('פרטים אישיים', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(user?.displayName ?? ''),
                    subtitle: Text(user?.email ?? ''),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('טלפון'),
                    subtitle: Text(user?.phoneNumber ?? 'לא זמין'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.work),
                    title: const Text('תפקיד'),
                    subtitle: Text(_getRoleName(user?.role)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (user?.role == UserRole.admin)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('בקשות עדכון פרופיל',
                            style: theme.textTheme.titleLarge),
                        if (notificationProvider.pendingProfileRequests > 0)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              notificationProvider.pendingProfileRequests
                                  .toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('profile_requests')
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('שגיאה: ${snapshot.error}');
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final requests = snapshot.data?.docs ?? [];
                        if (requests.isEmpty) {
                          return const Center(
                            child: Text('אין בקשות עדכון פרופיל ממתינות'),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            final request =
                                requests[index].data() as Map<String, dynamic>;
                            return ListTile(
                              leading:
                                  const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(
                                  request['displayName'] ?? 'משתמש ללא שם'),
                              subtitle: Text(request['email'] ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: () => _handleProfileRequest(
                                      context,
                                      requests[index].id,
                                      request['userId'],
                                      request,
                                      true,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => _handleProfileRequest(
                                      context,
                                      requests[index].id,
                                      request['userId'],
                                      request,
                                      false,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('הגדרות', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('הגדרות מערכת'),
                    onTap: () {
                      // Navigate to settings
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('התנתק'),
                    onTap: () {
                      authProvider.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleName(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return 'מנהל מערכת';
      case UserRole.team:
        return 'צוות';
      case UserRole.staff:
        return 'סטף';
      case UserRole.group:
        return 'קבוצה';
      case UserRole.user:
        return 'משתמש';
      case UserRole.developer:
        return 'מתכנת';
      default:
        return 'משתמש';
    }
  }

  Future<void> _handleProfileRequest(
    BuildContext context,
    String requestId,
    String userId,
    Map<String, dynamic> request,
    bool approved,
  ) async {
    try {
      if (approved) {
        // Update user profile
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'displayName': request['displayName'],
          'phoneNumber': request['phoneNumber'],
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      // Update request status
      await FirebaseFirestore.instance
          .collection('profile_requests')
          .doc(requestId)
          .update({
        'status': approved ? 'approved' : 'rejected',
        'handledBy': context.read<AuthProvider>().user?.uid,
        'handledAt': DateTime.now().toIso8601String(),
      });

      // Update notification count
      context
          .read<NotificationProvider>()
          .markProfileRequestAsHandled(requestId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approved ? 'בקשת העדכון אושרה' : 'בקשת העדכון נדחתה',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטיפול בבקשה: $e')),
        );
      }
    }
  }
}
