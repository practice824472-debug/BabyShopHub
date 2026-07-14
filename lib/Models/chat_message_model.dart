import 'package:cloud_firestore/cloud_firestore.dart';

/// A single message within a support chat thread between a user and admin.
class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderRole; // 'user' | 'admin'
  final String text;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  bool get isAdmin => senderRole == 'admin';

  factory ChatMessageModel.fromJson(Map<String, dynamic> json, String id) {
    return ChatMessageModel(
      id: id,
      senderId: json['senderId'] ?? '',
      senderRole: json['senderRole'] ?? 'user',
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
