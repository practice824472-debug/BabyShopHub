import 'package:cloud_firestore/cloud_firestore.dart';

/// A support chat conversation between one user and the admin. The doc id
/// in `chat_threads` is the user's uid, so each user has exactly one thread.
class ChatThreadModel {
  final String userId;
  final String userName;
  final String userEmail;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastSenderRole; // 'user' | 'admin'
  final bool unreadForAdmin;
  final bool unreadForUser;

  const ChatThreadModel({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderRole,
    required this.unreadForAdmin,
    required this.unreadForUser,
  });

  factory ChatThreadModel.fromJson(Map<String, dynamic> json, String id) {
    return ChatThreadModel(
      userId: id,
      userName: json['userName'] ?? 'User',
      userEmail: json['userEmail'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageAt: json['lastMessageAt'] != null
          ? (json['lastMessageAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastSenderRole: json['lastSenderRole'] ?? 'user',
      unreadForAdmin: json['unreadForAdmin'] ?? false,
      unreadForUser: json['unreadForUser'] ?? false,
    );
  }
}
