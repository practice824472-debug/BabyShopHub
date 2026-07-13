import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Manages the current user's wishlist, stored as a `wishlist` array field
/// (a list of productIds) on the user's `users/{uid}` document — the same
/// pattern already used for `addresses`.
class WishlistController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  List<String> _productIds = [];
  bool _isLoading = false;
  String? _error;

  List<String> get productIds => List.unmodifiable(_productIds);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _productIds.isEmpty;
  int get count => _productIds.length;

  String? get _uid => _auth.currentUser?.uid;

  bool isWishlisted(String productId) => _productIds.contains(productId);

  /// Starts listening to the current user's wishlist in real time.
  void listen() {
    final uid = _uid;
    if (uid == null) {
      _productIds = [];
      notifyListeners();
      return;
    }
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _firestore.collection('users').doc(uid).snapshots().listen(
      (snapshot) {
        final data = snapshot.data();
        _productIds = List<String>.from(data?['wishlist'] ?? []);
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Error loading wishlist: ${e.toString()}';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> toggle(String productId) async {
    if (isWishlisted(productId)) {
      await remove(productId);
    } else {
      await add(productId);
    }
  }

  Future<void> add(String productId) async {
    final uid = _uid;
    if (uid == null || _productIds.contains(productId)) return;

    final updated = [..._productIds, productId];
    _productIds = updated;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(uid).update({
        'wishlist': updated,
      });
    } catch (e) {
      _error = 'Failed to add to wishlist.';
      notifyListeners();
    }
  }

  Future<void> remove(String productId) async {
    final uid = _uid;
    if (uid == null) return;

    final updated = [..._productIds]..remove(productId);
    _productIds = updated;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(uid).update({
        'wishlist': updated,
      });
    } catch (e) {
      _error = 'Failed to remove from wishlist.';
      notifyListeners();
    }
  }

  void reset() {
    _subscription?.cancel();
    _subscription = null;
    _productIds = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
