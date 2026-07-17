import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Controllers/chat_controller.dart';
import '../../Models/chat_thread_model.dart';
import 'admin_chat_thread_screen.dart';

/// Admin live-chat inbox — lists every user thread, newest first,
/// with an unread badge. Tapping a row opens AdminChatThreadScreen.
class AdminChatInboxScreen extends StatefulWidget {
  const AdminChatInboxScreen({super.key});

  @override
  State<AdminChatInboxScreen> createState() => _AdminChatInboxScreenState();
}

class _AdminChatInboxScreenState extends State<AdminChatInboxScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ChatController>().listenToThreads());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Chat'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ChatController>(
        builder: (context, chat, _) {
          if (chat.threadsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chat.error != null && chat.threads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(chat.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => chat.listenToThreads(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (chat.threads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Users can start a chat from Help & Support.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chat.threads.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) =>
                _ThreadTile(thread: chat.threads[index]),
          );
        },
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final ChatThreadModel thread;

  const _ThreadTile({required this.thread});

  @override
  Widget build(BuildContext context) {
    final hasUnread = thread.unreadForAdmin;
    final isUserMessage = thread.lastSenderRole == 'user';

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.blue.shade100,
            foregroundColor: Colors.blue.shade700,
            child: Text(
              thread.userName.isNotEmpty
                  ? thread.userName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          if (hasUnread)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              thread.userName,
              style: TextStyle(
                fontWeight:
                    hasUnread ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatTime(thread.lastMessageAt),
            style: TextStyle(
              fontSize: 12,
              color:
                  hasUnread ? Colors.blue.shade700 : Colors.grey.shade500,
              fontWeight:
                  hasUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          if (!isUserMessage)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                'You: ',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500),
              ),
            ),
          Expanded(
            child: Text(
              thread.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: hasUnread
                    ? Colors.black87
                    : Colors.grey.shade600,
                fontWeight:
                    hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminChatThreadScreen(
              userId: thread.userId,
              userName: thread.userName,
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}
