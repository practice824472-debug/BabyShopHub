import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Models/notification_model.dart';

/// Manages the `notifications` Firestore collection (per-user documents
/// with a `userId` field, matching the `orders` collection convention).
class NotificationController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  String? get _uid => _auth.currentUser?.uid;

  void listen() {
    final uid = _uid;
    if (uid == null) {
      _notifications = [];
      notifyListeners();
      return;
    }
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen(
      (snapshot) {
        _notifications = snapshot.docs
            .map((doc) => NotificationModel.fromJson(doc.data(), doc.id))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Error loading notifications: ${e.toString()}';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final unread = _notifications.where((n) => !n.isRead);
    for (final n in unread) {
      await markAsRead(n.notificationId);
    }
  }

  /// Sends a notification to a specific user. Used both by order-status
  /// triggers and by the admin notification composer.
  static Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
    String? orderId,
  }) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'isRead': false,
      'createdAt': DateTime.now().toIso8601String(),
      'orderId': orderId,
    });
  }

  /// Sends the same notification to every user in [userIds]. Used for
  /// broadcast promo/coupon announcements from the admin panel.
  static Future<void> sendToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    NotificationType type = NotificationType.promo,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final collection = firestore.collection('notifications');
    for (final userId in userIds) {
      batch.set(collection.doc(), {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
        'orderId': null,
      });
    }
    await batch.commit();
  }

  void reset() {
    _subscription?.cancel();
    _subscription = null;
    _notifications = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
