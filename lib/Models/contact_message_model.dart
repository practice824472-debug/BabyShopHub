import 'package:cloud_firestore/cloud_firestore.dart';

/// A user-submitted message from the "Contact Us" tab of the Support
/// screen. Persisted so the admin panel can actually see and respond to
/// user inquiries, instead of the form just showing a fake success toast.
class ContactMessageModel {
  final String messageId;
  final String? userId;
  final String name;
  final String email;
  final String subject;
  final String message;
  final bool isResolved;
  final DateTime createdAt;

  const ContactMessageModel({
    required this.messageId,
    required this.userId,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    required this.isResolved,
    required this.createdAt,
  });

  factory ContactMessageModel.fromJson(
      Map<String, dynamic> json, String messageId) {
    return ContactMessageModel(
      messageId: messageId,
      userId: json['userId'] as String?,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      isResolved: json['isResolved'] ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
      'isResolved': isResolved,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
