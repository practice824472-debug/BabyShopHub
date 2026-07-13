import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../Models/contact_message_model.dart';

/// Manages the `contact_messages` Firestore collection: users submit
/// inquiries from the Support screen's "Contact Us" tab, and admins review
/// and resolve them from the admin panel.
class SupportController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ContactMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  List<ContactMessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  int get unresolvedCount => _messages.where((m) => !m.isResolved).length;

  Future<bool> submitMessage({
    required String? userId,
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await _firestore.collection('contact_messages').add(
            ContactMessageModel(
              messageId: '',
              userId: userId,
              name: name,
              email: email,
              subject: subject,
              message: message,
              isResolved: false,
              createdAt: DateTime.now(),
            ).toJson(),
          );
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to send message: ${e.toString()}';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Loads all contact messages for the admin panel, newest first.
  Future<void> loadMessages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final snapshot = await _firestore
          .collection('contact_messages')
          .orderBy('createdAt', descending: true)
          .get();
      _messages = snapshot.docs
          .map((doc) => ContactMessageModel.fromJson(doc.data(), doc.id))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load messages: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markResolved(String messageId, bool isResolved) async {
    try {
      await _firestore
          .collection('contact_messages')
          .doc(messageId)
          .update({'isResolved': isResolved});
      final index = _messages.indexWhere((m) => m.messageId == messageId);
      if (index != -1) {
        final m = _messages[index];
        _messages[index] = ContactMessageModel(
          messageId: m.messageId,
          userId: m.userId,
          name: m.name,
          email: m.email,
          subject: m.subject,
          message: m.message,
          isResolved: isResolved,
          createdAt: m.createdAt,
        );
        notifyListeners();
      }
    } catch (_) {}
  }
}
