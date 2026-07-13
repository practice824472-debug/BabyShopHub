import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Models/coupon_model.dart';

/// Manages the `coupons` Firestore collection: admin CRUD plus
/// checkout-time validation/redemption for the current user.
class CouponController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  List<CouponModel> _coupons = [];
  bool _isLoading = false;
  String? _error;

  // The coupon currently applied at checkout (if any).
  CouponModel? _appliedCoupon;

  List<CouponModel> get coupons => List.unmodifiable(_coupons);
  bool get isLoading => _isLoading;
  String? get error => _error;
  CouponModel? get appliedCoupon => _appliedCoupon;

  String? get _uid => _auth.currentUser?.uid;

  /// Loads all coupons (admin management screen).
  void loadCoupons() {
    _subscription ??= _firestore.collection('coupons').snapshots().listen(
      (snapshot) {
        _coupons = snapshot.docs
            .map((doc) => CouponModel.fromJson(doc.data(), doc.id))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Error loading coupons: ${e.toString()}';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> createCoupon(CouponModel coupon) async {
    try {
      await _firestore.collection('coupons').add(coupon.toJson());
      return true;
    } catch (e) {
      _error = 'Failed to create coupon: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCoupon(String couponId, CouponModel coupon) async {
    try {
      await _firestore.collection('coupons').doc(couponId).update(coupon.toJson());
      return true;
    } catch (e) {
      _error = 'Failed to update coupon: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCoupon(String couponId) async {
    try {
      await _firestore.collection('coupons').doc(couponId).delete();
      return true;
    } catch (e) {
      _error = 'Failed to delete coupon: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleActive(CouponModel coupon) async {
    return updateCoupon(coupon.couponId,
        CouponModel.fromJson({...coupon.toJson(), 'isActive': !coupon.isActive}, coupon.couponId));
  }

  /// Validates [code] for the current user and, if valid, applies it.
  /// Returns an error message on failure, or null on success.
  Future<String?> applyCoupon(String code, double subtotal) async {
    final uid = _uid;
    if (uid == null) return 'You must be signed in to use a coupon.';

    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return 'Enter a coupon code.';

    try {
      final query = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: normalized)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return 'Invalid coupon code.';

      final coupon = CouponModel.fromJson(query.docs.first.data(), query.docs.first.id);

      if (!coupon.isActive) return 'This coupon is no longer active.';
      if (coupon.isExpired) return 'This coupon has expired.';
      if (coupon.usedBy.contains(uid)) return 'You have already used this coupon.';
      if (coupon.isUsageExhausted) return 'This coupon has reached its usage limit.';

      _appliedCoupon = coupon;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Failed to validate coupon: ${e.toString()}';
    }
  }

  void removeAppliedCoupon() {
    _appliedCoupon = null;
    notifyListeners();
  }

  double discountAmount(double subtotal) {
    if (_appliedCoupon == null) return 0;
    return _appliedCoupon!.discountFor(subtotal);
  }

  /// Marks the applied coupon as used by the current user. Call after an
  /// order is successfully placed.
  Future<void> markCouponUsed() async {
    final uid = _uid;
    final coupon = _appliedCoupon;
    if (uid == null || coupon == null) return;

    try {
      await _firestore.collection('coupons').doc(coupon.couponId).update({
        'usedBy': FieldValue.arrayUnion([uid]),
      });
    } catch (_) {
      // Non-fatal: order already placed; don't block the user on this.
    }
    _appliedCoupon = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
