import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../Models/cart_model.dart';
import '../Models/order_model.dart';

class OrderController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isPlacing = false;
  bool _isFetching = false;
  String? _error;
  OrderModel? _lastOrder;
  List<OrderModel> _orders = [];

  bool get isPlacing => _isPlacing;
  bool get isFetching => _isFetching;
  String? get error => _error;
  OrderModel? get lastOrder => _lastOrder;
  List<OrderModel> get orders => List.unmodifiable(_orders);

  String? get _uid => _auth.currentUser?.uid;

  /// Fetches all orders for the current user, newest first.
  Future<void> fetchUserOrders() async {
    final uid = _uid;
    if (uid == null) {
      _orders = [];
      notifyListeners();
      return;
    }

    _isFetching = true;
    _error = null;
    notifyListeners();

    try {
      // NOTE: combining .where() + .orderBy() on different fields requires a
      // Firestore composite index. Sort in memory to avoid the index requirement.
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .get();

      _orders = snapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  /// Places a new order in Firestore and returns the saved [OrderModel].
  /// Throws on failure so the UI can surface the error.
  Future<OrderModel> placeOrder({
    required List<CartItem> cartItems,
    required OrderAddress address,
    required String paymentMethod,
    required double totalPrice,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in.');

    _isPlacing = true;
    _error = null;
    notifyListeners();

    try {
      final orderId = const Uuid().v4();

      final items = cartItems
          .map(
            (c) => OrderItem(
          productId: c.productId,
          name: c.name,
          brand: c.brand,
          image: c.image,
          price: c.price,
          quantity: c.quantity,
        ),
      )
          .toList();

      final order = OrderModel(
        orderId: orderId,
        userId: uid,
        items: items,
        address: address,
        paymentMethod: paymentMethod,
        status: OrderStatus.pending,
        totalPrice: totalPrice,
        createdAt: DateTime.now(),
      );

      // Persist customer details alongside the order so the admin order list
      // and details view can display name / email / phone / address. These
      // are the exact keys AdminOrderModel reads.
      final data = order.toJson();
      data['userName'] = address.fullName;
      data['userEmail'] = _auth.currentUser?.email ?? '';
      data['userPhone'] = address.phone;
      data['shippingAddress'] =
          '${address.addressLine}, ${address.city} ${address.postalCode}';
      data['stockDeducted'] = false;

      await _firestore.collection('orders').doc(orderId).set(data);

      _lastOrder = order;
      return order;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isPlacing = false;
      notifyListeners();
    }
  }

  /// Updates order status and reduces product stock when order is delivered
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final orderDoc =
      await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return false;

      final orderData = orderDoc.data() ?? {};
      final items = (orderData['items'] as List<dynamic>?) ?? [];

      // Reduce stock for each item when order is delivered
      if (newStatus == OrderStatus.delivered) {
        for (var item in items) {
          final productId = item['productId'] as String?;
          final quantity = item['quantity'] as int? ?? 0;

          if (productId != null && quantity > 0) {
            // Get current stock
            final productDoc = await _firestore
                .collection('products')
                .doc(productId)
                .get();
            if (productDoc.exists) {
              final currentStock = (productDoc.data()?['stock'] as int?) ?? 0;
              final newStock = (currentStock - quantity).clamp(0, 999999);

              // Update product stock
              await _firestore
                  .collection('products')
                  .doc(productId)
                  .update({'stock': newStock});
            }
          }
        }
      }

      // Update order status
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  void clearLastOrder() {
    _lastOrder = null;
    notifyListeners();
  }

  /// Returns a live Firestore stream for a single order by [orderId].
  Stream<OrderModel> streamOrder(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((snap) => OrderModel.fromJson(snap.data() ?? {}));
  }
}
