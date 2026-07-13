import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { order, promo, general }

class NotificationModel {
  final String notificationId;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? orderId;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.body,
    this.type = NotificationType.general,
    this.isRead = false,
    required this.createdAt,
    this.orderId,
  });

  factory NotificationModel.fromJson(
      Map<String, dynamic> json, String notificationId) {
    return NotificationModel(
      notificationId: notificationId,
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NotificationType.general,
      ),
      isRead: json['isRead'] ?? false,
      createdAt: _toDateTime(json['createdAt']) ?? DateTime.now(),
      orderId: json['orderId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'orderId': orderId,
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
