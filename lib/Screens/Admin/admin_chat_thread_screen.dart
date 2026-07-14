import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Controllers/chat_controller.dart';
import '../../Widgets/chat_view.dart';

/// The admin's side of a single user's support chat thread.
class AdminChatThreadScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminChatThreadScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminChatThreadScreen> createState() => _AdminChatThreadScreenState();
}

class _AdminChatThreadScreenState extends State<AdminChatThreadScreen> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => context.read<ChatController>().openThread(widget.userId));
  }

  @override
  void dispose() {
    _textController.dispose();
    context.read<ChatController>().closeThread();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    final chat = context.read<ChatController>();
    _textController.clear();
    await chat.sendMessage(
      userId: widget.userId,
      isAdmin: true,
      text: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: Consumer<ChatController>(
        builder: (context, chat, _) {
          return ChatView(
            messages: chat.messages,
            isLoading: chat.messagesLoading,
            isSending: chat.isSending,
            error: chat.error,
            viewerIsAdmin: true,
            textController: _textController,
            onSend: _send,
            emptyTitle: 'No messages yet',
            emptyMessage: 'Reply here to start helping this user.',
          );
        },
      ),
    );
  }
}
