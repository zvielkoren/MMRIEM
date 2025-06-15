import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isGroupMessage = false;
  String? _selectedUserId;
  Map<String, dynamic>? _replyingTo;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
      final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) return;

    // אם המשתמש הוא לא מתכנת, מנהל או צוות, נחפש מתכנת לצ'אט
    if (currentUser.role == UserRole.user ||
        currentUser.role == UserRole.group) {
      try {
        final developerSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: UserRole.developer.name)
            .limit(1)
            .get();

        if (developerSnapshot.docs.isNotEmpty) {
          setState(() {
            _selectedUserId = developerSnapshot.docs.first.id;
          });
        }
      } catch (e) {
        debugPrint('Error finding developer: $e');
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildUserSelector() {
    final currentUser = context.read<AuthProvider>().user;
    final isDeveloper = currentUser?.role == UserRole.developer;
    final isAdmin = currentUser?.role == UserRole.admin;
    final isTeam = currentUser?.role == UserRole.team;

    // אם המשתמש הוא משתמש רגיל או קבוצה, לא נציג את בורר המשתמשים
    if (currentUser?.role == UserRole.user ||
        currentUser?.role == UserRole.group) {
      return const SizedBox.shrink();
    }

    // אם זו הודעה קבוצתית או שהמשתמש אינו מתכנת/מנהל/צוות, לא נציג את הבורר
    if (_isGroupMessage || (!isDeveloper && !isAdmin && !isTeam)) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: [
        UserRole.admin.name,
        UserRole.team.name,
        UserRole.staff.name,
        UserRole.user.name,
        if (isDeveloper) UserRole.developer.name,
      ]).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('שגיאה: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return DropdownMenuItem(
                value: doc.id,
                child: Text(data['displayName'] ?? 'משתמש לא ידוע'),
              );
            }).toList() ??
            [];

        if (users.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('אין משתמשים זמינים'),
            ),
          );
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'בחר משתמש לשליחת הודעה:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _selectedUserId,
                hint: const Text('בחר משתמש'),
                isExpanded: true,
                items: users,
                onChanged: (value) {
                  setState(() {
                    _selectedUserId = value;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) return;

    final isDeveloper = currentUser.role == UserRole.developer;

    try {
      if (!isDeveloper && _selectedUserId == null) {
        // מחפש משתמש מתכנת
        final developerSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: UserRole.developer.name)
            .limit(1)
            .get();

        if (developerSnapshot.docs.isNotEmpty) {
          _selectedUserId = developerSnapshot.docs.first.id;
        }
      }

      final message = {
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? '',
        'content': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isGroupMessage': isDeveloper && _isGroupMessage,
        'receiverId': isDeveloper && _isGroupMessage
            ? null
            : isDeveloper
                ? _selectedUserId
                : _selectedUserId,
        if (_replyingTo != null) ...{
          'replyTo': {
            'messageId': _replyingTo!['messageId'],
            'content': _replyingTo!['content'],
            'senderName': _replyingTo!['senderName'],
          },
        },
      };

      if (isDeveloper && _isGroupMessage) {
        // שליחת הודעה קבוצתית
        await FirebaseFirestore.instance
            .collection('group_messages')
            .add(message);

        // שליחת התראה לכל המשתמשים
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', whereIn: [
          UserRole.admin.name,
          UserRole.team.name,
          UserRole.staff.name,
          UserRole.user.name,
          UserRole.group.name,
        ]).get();

        final batch = FirebaseFirestore.instance.batch();
        for (var userDoc in usersSnapshot.docs) {
          if (userDoc.id != currentUser.uid) {
            // לא לשלוח התראה למתכנת עצמו
            batch.set(
              FirebaseFirestore.instance.collection('notifications').doc(),
              {
                'userId': userDoc.id,
                'title': 'הודעה חדשה מהמתכנת',
                'body': _messageController.text.trim(),
                'type': 'group_message',
                'isRead': false,
                'timestamp': FieldValue.serverTimestamp(),
                'data': {
                  'messageId': null, // יתעדכן לאחר שליחת ההודעה
                  'senderId': currentUser.uid,
                  'senderName': currentUser.displayName,
                }
              },
            );
          }
        }
        await batch.commit();
      } else {
        await FirebaseFirestore.instance
            .collection('private_messages')
            .add(message);
      }

      _messageController.clear();
      setState(() {
        _replyingTo = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בשליחת ההודעה: $e')),
        );
      }
    }
  }

  Widget _buildReplyPreview() {
    if (_replyingTo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'בתגובה ל-${_replyingTo!['senderName']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  _replyingTo!['content'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _replyingTo = null),
            tooltip: 'בטל תגובה',
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> message, bool isCurrentUser, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser)
            Text(
              message['senderName'] ?? 'משתמש לא ידוע',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (message['replyTo'] != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['replyTo']['senderName'] ?? 'משתמש לא ידוע',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isCurrentUser
                          ? theme.colorScheme.onPrimary.withOpacity(0.7)
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    message['replyTo']['content'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: isCurrentUser
                          ? theme.colorScheme.onPrimary.withOpacity(0.7)
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Text(
            message['content'] ?? '',
            style: TextStyle(
              color: isCurrentUser
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (message['timestamp'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatTimestamp(
                  (message['timestamp'] as Timestamp).toDate(),
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrentUser
                      ? theme.colorScheme.onPrimary.withOpacity(0.7)
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, Map<String, dynamic> message,
      String messageId, bool isCurrentUser, User? currentUser) {
    final theme = Theme.of(context);
    final isDeveloper = currentUser?.role == UserRole.developer;

    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('הגב'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _replyingTo = {
                      'messageId': messageId,
                      'content': message['content'],
                      'senderName': message['senderName'],
                    };
                  });
                  _messageController.text = '';
                },
              ),
              if (isDeveloper || isCurrentUser)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('מחק'),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('מחיקת הודעה'),
                        content: const Text('האם למחוק את ההודעה?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('ביטול'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('מחק'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      _deleteMessage(messageId, _isGroupMessage);
                    }
                  },
                ),
            ],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
          vertical: 4.0,
        ),
        child: Row(
          mainAxisAlignment:
              isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isCurrentUser) ...[
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  ((message['senderName'] as String?)?.isNotEmpty ?? false)
                      ? message['senderName']!.substring(0, 1)
                      : '?',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: _buildMessageBubble(message, isCurrentUser, theme),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  ((currentUser?.displayName ?? '').isNotEmpty)
                      ? currentUser!.displayName.substring(0, 1)
                      : '?',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;
    final theme = Theme.of(context);
    final isDeveloper = currentUser?.role == UserRole.developer;

    // בדיקה שהמשתמש מחובר
    if (currentUser == null) {
      return const Center(
        child: Text('יש להתחבר כדי להשתמש בצ\'אט'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isDeveloper ? 'ניהול צ\'אט' : 'צ\'אט עם המתכנת'),
        automaticallyImplyLeading: false,
        actions: isDeveloper
            ? [
          IconButton(
                  icon: Icon(
                    _isGroupMessage ? Icons.group : Icons.person,
                  ),
            onPressed: () {
                    setState(() {
                      _isGroupMessage = !_isGroupMessage;
                      if (_isGroupMessage) {
                        _selectedUserId = null;
                      }
                    });
                  },
                  tooltip: _isGroupMessage ? 'הודעה לכולם' : 'צ\'אט פרטי',
                ),
                // הוספת כפתור ניקוי צ'אט למתכנת
                if (!_isGroupMessage && _selectedUserId != null)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    onPressed: () => _clearChat(_selectedUserId!),
                    tooltip: 'נקה צ\'אט',
                  ),
              ]
            : null,
      ),
      body: Column(
        children: [
          if (isDeveloper && !_isGroupMessage) ...[
            _buildUserSelector(),
          ],
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: isDeveloper && _isGroupMessage
                  ? FirebaseFirestore.instance
                      .collection('group_messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('private_messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('שגיאה: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (isDeveloper) {
                        if (_isGroupMessage) {
                          return data['isGroupMessage'] == true;
                        } else {
                          return _selectedUserId != null &&
                              (data['senderId'] == _selectedUserId ||
                                  data['receiverId'] == _selectedUserId);
                        }
                      } else {
                        return data['senderId'] == currentUser.uid ||
                            data['receiverId'] == currentUser.uid;
                      }
                    }).toList() ??
                    [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('אין הודעות עדיין'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>;
                    final messageId = messages[index].id;
                    final isCurrentUser =
                        message['senderId'] == currentUser.uid;

                    return _buildMessageItem(
                      context,
                      message,
                      messageId,
                      isCurrentUser,
                      currentUser,
                    );
                  },
                );
              },
            ),
          ),
          _buildReplyPreview(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'הקלד הודעה...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _deleteMessage(String messageId, bool isGroupMessage) async {
    try {
      final collection = isGroupMessage ? 'group_messages' : 'private_messages';
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(messageId)
          .delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה במחיקת ההודעה: $e')),
        );
      }
    }
  }

  Future<void> _clearChat(String userId) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ניקוי צ\'אט'),
          content:
              const Text('האם אתה בטוח שברצונך למחוק את כל ההודעות בצ\'אט זה?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ביטול'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('מחק הכל'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final currentUser = context.read<AuthProvider>().user;
        final batch = FirebaseFirestore.instance.batch();
        final messages = await FirebaseFirestore.instance
            .collection('private_messages')
            .where('senderId', whereIn: [userId, currentUser?.uid]).where(
                'receiverId',
                whereIn: [userId, currentUser?.uid]).get();

        for (var doc in messages.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('הצ\'אט נוקה בהצלחה')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בניקוי הצ\'אט: $e')),
        );
      }
    }
  }
}
