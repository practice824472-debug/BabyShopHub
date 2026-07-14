import 'package:flutter/material.dart';

import '../Models/chat_message_model.dart';
import '../Utils/app_theme.dart';

/// Shared message-list + input UI for a support chat thread. Used by both
/// the user's "Chat" tab and the admin's chat thread screen — only the
/// role/callbacks differ.
class ChatView extends StatelessWidget {
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final bool viewerIsAdmin;
  final TextEditingController textController;
  final VoidCallback onSend;
  final String emptyTitle;
  final String emptyMessage;

  const ChatView({
    super.key,
    required this.messages,
    required this.isLoading,
    required this.isSending,
    required this.error,
    required this.viewerIsAdmin,
    required this.textController,
    required this.onSend,
    this.emptyTitle = 'No messages yet',
    this.emptyMessage = 'Send a message to start the conversation.',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(error!, textAlign: TextAlign.center),
                      ),
                    )
                  : messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    size: 56, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(emptyTitle,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700)),
                                const SizedBox(height: 6),
                                Text(emptyMessage,
                                    textAlign: TextAlign.center,
                                    style:
                                        TextStyle(color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.all(12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            // A bubble is "mine" if it was sent by whichever
                            // role is currently viewing the thread.
                            final isMine = viewerIsAdmin
                                ? message.isAdmin
                                : !message.isAdmin;
                            return _MessageBubble(
                              text: message.text,
                              isMine: isMine,
                              senderLabel: message.isAdmin ? 'Support' : 'You',
                              time: message.createdAt,
                            );
                          },
                        ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: 'Type a message…',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: isSending ? null : onSend,
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final String senderLabel;
  final DateTime time;

  const _MessageBubble({
    required this.text,
    required this.isMine,
    required this.senderLabel,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMine ? AppTheme.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMine ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(time),
              style: TextStyle(
                fontSize: 10,
                color: isMine ? Colors.white70 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
