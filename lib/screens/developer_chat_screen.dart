import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../models/chat_message.dart';

class DeveloperChatScreen extends StatefulWidget {
  const DeveloperChatScreen({super.key});

  @override
  State<DeveloperChatScreen> createState() => _DeveloperChatScreenState();
}

class _DeveloperChatScreenState extends State<DeveloperChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadActiveChats();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendLogsToDeveloper(String userId) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;

      final logs = {
        'timestamp': DateTime.now().toIso8601String(),
        'user': {
          'id': user?.id,
          'email': user?.email,
          'role': user?.role.toString(),
          'displayName': user?.displayName,
        },
        'device': {'platform': Theme.of(context).platform.toString()},
        'lastError': authProvider.error,
      };

      await context.read<ChatProvider>().sendLogsToDeveloper(userId, logs);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הלוגים נשלחו למתכנת בהצלחה')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('שגיאה בשליחת הלוגים: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatProvider = context.watch<ChatProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ניהול צ\'אטים'),
        actions: [
          if (chatProvider.currentChatUserId != null) ...[
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('מחיקת צ\'אט'),
                        content: const Text(
                          'האם אתה בטוח שברצונך למחוק את כל ההודעות בצ\'אט זה?',
                        ),
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

                if (confirmed == true && mounted) {
                  await chatProvider.clearChat(chatProvider.currentChatUserId!);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed:
                  () => _sendLogsToDeveloper(chatProvider.currentChatUserId!),
            ),
          ],
        ],
      ),
      body: Row(
        children: [
          // רשימת הצ'אטים הפעילים
          Container(
            width: 250,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: theme.dividerColor)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'צ\'אטים פעילים',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: chatProvider.activeChats.length,
                    itemBuilder: (context, index) {
                      final userId = chatProvider.activeChats[index];
                      return ListTile(
                        title: Text('משתמש #$userId'),
                        selected: userId == chatProvider.currentChatUserId,
                        onTap: () => chatProvider.loadMessages(userId),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // אזור הצ'אט
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: chatProvider.messagesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('שגיאה: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data!;

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(8.0),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == currentUser?.id;

                          return Align(
                            alignment:
                                isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 4.0,
                                horizontal: 8.0,
                              ),
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color:
                                    isMe
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.secondary,
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.senderName,
                                    style: TextStyle(
                                      color:
                                          isMe
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      color:
                                          isMe
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(message.timestamp),
                                    style: TextStyle(
                                      color:
                                          isMe
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'הקלד הודעה...',
                            border: OutlineInputBorder(),
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
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.user;

    if (currentUser != null && chatProvider.currentChatUserId != null) {
      chatProvider.sendMessage(content, currentUser);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
