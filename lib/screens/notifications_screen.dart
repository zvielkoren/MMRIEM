import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../models/notification.dart' as app_notification;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = context.watch<AuthProvider>().user;
    final isAdmin = currentUser?.role == UserRole.admin;
    final isTeam = currentUser?.role == UserRole.team;

    return Scaffold(
      appBar: AppBar(
        title: const Text('התראות'),
        actions: [
          if (isAdmin || isTeam)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('מחיקת כל ההתראות'),
                    content:
                        const Text('האם אתה בטוח שברצונך למחוק את כל ההתראות?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('ביטול'),
                      ),
                      TextButton(
                        onPressed: () {
                          context
                              .read<NotificationProvider>()
                              .deleteAllNotifications();
                          Navigator.pop(context);
                        },
                        child: const Text('מחק הכל'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'אין התראות חדשות',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return Dismissible(
                key: Key(notification.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: theme.colorScheme.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                onDismissed: (direction) {
                  provider.deleteNotification(notification.id);
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(notification.title),
                  subtitle: Text(notification.body),
                  trailing: Text(
                    DateFormat('HH:mm dd/MM/yyyy')
                        .format(notification.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                  onTap: () {
                    provider.markAsRead(notification.id);
                    _handleNotificationTap(context, notification);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isAdmin || isTeam
          ? FloatingActionButton(
              onPressed: () {
                _showCreateNotificationDialog(context);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  IconData _getNotificationIcon(app_notification.NotificationType type) {
    switch (type) {
      case app_notification.NotificationType.message:
        return Icons.message;
      case app_notification.NotificationType.profileRequest:
        return Icons.person;
      case app_notification.NotificationType.system:
        return Icons.notifications;
    }
  }

  void _handleNotificationTap(
      BuildContext context, app_notification.Notification notification) {
    switch (notification.type) {
      case app_notification.NotificationType.message:
        Navigator.pushNamed(context, '/chat');
        break;
      case app_notification.NotificationType.profileRequest:
        Navigator.pushNamed(context, '/profile');
        break;
      case app_notification.NotificationType.system:
        // Handle system notification tap
        break;
    }
  }

  void _showCreateNotificationDialog(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedUserId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('שליחת הודעה חדשה'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('שגיאה בטעינת משתמשים');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    final users = snapshot.data?.docs ?? [];

                    return DropdownButtonFormField<String>(
                      value: selectedUserId,
                      decoration: const InputDecoration(
                        labelText: 'בחר משתמש',
                      ),
                      items: users.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(data['displayName'] ?? 'משתמש לא ידוע'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedUserId = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'נא לבחור משתמש';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'כותרת',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'נא להזין כותרת';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'תוכן ההודעה',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'נא להזין תוכן';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final notificationProvider =
                    Provider.of<NotificationProvider>(context, listen: false);

                await notificationProvider.sendMessage(
                  userId: selectedUserId!,
                  title: titleController.text.trim(),
                  message: messageController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ההודעה נשלחה בהצלחה'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text('שלח'),
          ),
        ],
      ),
    );
  }
}
