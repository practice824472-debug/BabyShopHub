import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Models/chat_message_model.dart';
import '../Models/chat_thread_model.dart';

/// Manages the `chat_threads` Firestore collection (one document per user,
/// keyed by uid, with a `messages` subcollection) that powers the live
/// support chat between a user and the admin.
class ChatController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _threadsSub;

  List<ChatMessageModel> _messages = [];
  List<ChatThreadModel> _threads = [];
  bool _messagesLoading = false;
  bool _threadsLoading = false;
  bool _isSending = false;
  String? _error;
  String? _openThreadUserId;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  List<ChatThreadModel> get threads => List.unmodifiable(_threads);
  bool get messagesLoading => _messagesLoading;
  bool get threadsLoading => _threadsLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  int get unreadThreadsCount => _threads.where((t) => t.unreadForAdmin).length;

  String? get _uid => _auth.currentUser?.uid;

  /// Opens (and starts listening to) the signed-in user's own chat with
  /// the admin. Marks it read for the user side.
  void openMyChat() {
    final uid = _uid;
    if (uid == null) return;
    _listenToThread(uid);
    _firestore.collection('chat_threads').doc(uid).set(
      {'unreadForUser': false},
      SetOptions(merge: true),
    ).catchError((_) {});
  }

  /// Opens (and starts listening to) a specific user's thread — used by
  /// the admin. Marks it read for the admin side.
  void openThread(String userId) {
    _listenToThread(userId);
    _firestore.collection('chat_threads').doc(userId).set(
      {'unreadForAdmin': false},
      SetOptions(merge: true),
    ).catchError((_) {});
  }

  void _listenToThread(String userId) {
    if (_openThreadUserId == userId && _messagesSub != null) return;
    _openThreadUserId = userId;
    _messagesSub?.cancel();
    _messages = [];
    _messagesLoading = true;
    _error = null;
    notifyListeners();

    _messagesSub = _firestore
        .collection('chat_threads')
        .doc(userId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _messages = snapshot.docs
            .map((doc) => ChatMessageModel.fromJson(doc.data(), doc.id))
            .toList();
        _messagesLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Error loading chat: ${e.toString()}';
        _messagesLoading = false;
        notifyListeners();
      },
    );
  }

  /// Sends a message in [userId]'s thread. [isAdmin] controls who the
  /// sender is; [userName]/[userEmail] seed the thread doc the first time
  /// a user messages (so the admin's thread list has something to show).
  Future<bool> sendMessage({
    required String userId,
    required bool isAdmin,
    required String text,
    String? userName,
    String? userEmail,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    _isSending = true;
    notifyListeners();

    try {
      final senderId = isAdmin ? 'admin' : (_uid ?? userId);
      final threadRef = _firestore.collection('chat_threads').doc(userId);

      await threadRef.collection('messages').add(
            ChatMessageModel(
              id: '',
              senderId: senderId,
              senderRole: isAdmin ? 'admin' : 'user',
              text: trimmed,
              createdAt: DateTime.now(),
            ).toJson(),
          );

      await threadRef.set({
        'userId': userId,
        if (userName != null) 'userName': userName,
        if (userEmail != null) 'userEmail': userEmail,
        'lastMessage': trimmed,
        'lastMessageAt': Timestamp.fromDate(DateTime.now()),
        'lastSenderRole': isAdmin ? 'admin' : 'user',
        'unreadForAdmin': !isAdmin,
        'unreadForUser': isAdmin,
      }, SetOptions(merge: true));

      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to send message: ${e.toString()}';
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// Streams every user's thread, newest activity first — used by the
  /// admin's Live Chat inbox.
  void listenToThreads() {
    _threadsSub?.cancel();
    _threadsLoading = true;
    notifyListeners();

    _threadsSub = _firestore
        .collection('chat_threads')
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _threads = snapshot.docs
            .map((doc) => ChatThreadModel.fromJson(doc.data(), doc.id))
            .toList();
        _threadsLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Error loading chats: ${e.toString()}';
        _threadsLoading = false;
        notifyListeners();
      },
    );
  }

  /// Stops listening to the currently open thread (call when leaving the
  /// chat screen so a stale subscription doesn't linger).
  void closeThread() {
    _messagesSub?.cancel();
    _messagesSub = null;
    _openThreadUserId = null;
    _messages = [];
  }

  void reset() {
    _messagesSub?.cancel();
    _messagesSub = null;
    _threadsSub?.cancel();
    _threadsSub = null;
    _openThreadUserId = null;
    _messages = [];
    _threads = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _threadsSub?.cancel();
    super.dispose();
  }
}
