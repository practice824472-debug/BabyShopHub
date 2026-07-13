import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Controllers/support_controller.dart';
import '../../Models/contact_message_model.dart';

/// Admin view of user "Contact Us" submissions from the Support screen,
/// so inquiries actually reach someone instead of vanishing into a fake
/// success toast.
class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  bool _showUnresolvedOnly = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<SupportController>().loadMessages());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Messages'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: Consumer<SupportController>(
        builder: (context, supportCtrl, _) {
          if (supportCtrl.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (supportCtrl.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(supportCtrl.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => supportCtrl.loadMessages(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            );
          }

          final messages = _showUnresolvedOnly
              ? supportCtrl.messages.where((m) => !m.isResolved).toList()
              : supportCtrl.messages;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${supportCtrl.unresolvedCount} unresolved of ${supportCtrl.messages.length} total',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    FilterChip(
                      label: const Text('Unresolved only'),
                      selected: _showUnresolvedOnly,
                      onSelected: (v) => setState(() => _showUnresolvedOnly = v),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mark_email_read_outlined,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _showUnresolvedOnly
                                  ? 'No unresolved messages'
                                  : 'No messages yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => supportCtrl.loadMessages(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) =>
                              _MessageCard(message: messages[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final ContactMessageModel message;

  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        leading: Icon(
          message.isResolved ? Icons.check_circle : Icons.circle_notifications,
          color: message.isResolved ? Colors.green : Colors.orange,
        ),
        title: Text(
          message.subject,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${message.name} • ${message.email}'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.message, style: TextStyle(color: Colors.grey.shade800)),
                const SizedBox(height: 12),
                Text(
                  _formatDate(message.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => context
                        .read<SupportController>()
                        .markResolved(message.messageId, !message.isResolved),
                    icon: Icon(
                      message.isResolved ? Icons.undo : Icons.check,
                      size: 18,
                    ),
                    label: Text(
                      message.isResolved ? 'Mark unresolved' : 'Mark resolved',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
