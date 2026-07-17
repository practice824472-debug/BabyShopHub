import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/admin_order_model.dart';
import '../Models/admin_product_model.dart';
import '../Models/admin_user_model.dart';
import '../Models/admin_dashboard_model.dart';
import '../Models/notification_model.dart';
import 'notification_controller.dart';

class AdminController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Dashboard Stats
  AdminDashboardStats? _dashboardStats;
  AdminDashboardStats? get dashboardStats => _dashboardStats;

  // Products
  List<AdminProductModel> _products = [];
  List<AdminProductModel> get products => _products;
  bool _productsLoading = false;
  bool get productsLoading => _productsLoading;

  // Orders
  List<AdminOrderModel> _orders = [];
  List<AdminOrderModel> get orders => _orders;
  bool _ordersLoading = false;
  bool get ordersLoading => _ordersLoading;

  // Users
  List<AdminUserModel> _users = [];
  List<AdminUserModel> get users => _users;
  bool _usersLoading = false;
  bool get usersLoading => _usersLoading;

  // Error handling
  String? _error;
  String? get error => _error;

  // ============ DASHBOARD METHODS ============

  Future<void> loadDashboardStats() async {
    try {
      _error = null;
      notifyListeners();

      final totalUsersSnap =
      await _firestore.collection('users').where('role', isNotEqualTo: 'admin').get();
      final totalOrdersSnap = await _firestore.collection('orders').get();
      final totalProductsSnap = await _firestore.collection('products').get();

      // Calculate revenue
      double revenue = 0;
      int pendingOrders = 0;
      for (var order in totalOrdersSnap.docs) {
        revenue += (order['totalPrice'] ?? 0).toDouble();
        if (order['status'] == 'pending') {
          pendingOrders++;
        }
      }

      int activeProducts = totalProductsSnap.docs
          .where((doc) => doc['isActive'] == true)
          .length;

      _dashboardStats = AdminDashboardStats(
        totalUsers: totalUsersSnap.size,
        totalOrders: totalOrdersSnap.size,
        totalProducts: totalProductsSnap.size,
        revenue: revenue,
        pendingOrders: pendingOrders,
        activeProducts: activeProducts,
        lastUpdated: DateTime.now(),
      );

      notifyListeners();
    } catch (e) {
      _error = 'Error loading dashboard stats: ${e.toString()}';
      notifyListeners();
    }
  }

  // ============ PRODUCT MANAGEMENT METHODS ============

  Future<void> loadProducts() async {
    try {
      _productsLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore.collection('products').get();
      _products = snapshot.docs
          .map((doc) => AdminProductModel.fromJson(doc.data(), doc.id))
          .toList();

      _productsLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading products: ${e.toString()}';
      _productsLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(AdminProductModel product) async {
    try {
      _error = null;
      await _firestore.collection('products').add(product.toJson());
      await loadProducts();
      notifyListeners();
    } catch (e) {
      _error = 'Error adding product: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> updateProduct(String productId, AdminProductModel product) async {
    try {
      _error = null;
      await _firestore.collection('products').doc(productId).update(product.toJson());
      await loadProducts();
      notifyListeners();
    } catch (e) {
      _error = 'Error updating product: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      _error = null;
      await _firestore.collection('products').doc(productId).delete();
      await loadProducts();
      notifyListeners();
    } catch (e) {
      _error = 'Error deleting product: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> updateProductStock(String productId, int newStock) async {
    try {
      _error = null;
      await _firestore.collection('products').doc(productId).update({
        'stock': newStock,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await loadProducts();
      notifyListeners();
    } catch (e) {
      _error = 'Error updating stock: ${e.toString()}';
      notifyListeners();
    }
  }

  // ============ ORDER MANAGEMENT METHODS ============

  Future<void> loadOrders() async {
    try {
      _ordersLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      _orders = snapshot.docs
          .map((doc) => AdminOrderModel.fromJson(doc.data(), doc.id))
          .toList();

      _ordersLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading orders: ${e.toString()}';
      _ordersLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(
      String orderId, OrderStatus newStatus) async {
    try {
      _error = null;
      final statusString = newStatus.toString().split('.').last;

      Map<String, dynamic> updateData = {
        'status': statusString,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (newStatus == OrderStatus.delivered) {
        updateData['deliveredAt'] = DateTime.now().toIso8601String();
        await _reduceStockForOrder(orderId);
        updateData['stockDeducted'] = true;
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);
      await _notifyOrderStatusChange(orderId, newStatus);
      await loadOrders();
      notifyListeners();
    } catch (e) {
      _error = 'Error updating order: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Notifies the order's owner whenever an admin changes its status, so
  /// the customer sees it in their notification center in real time.
  Future<void> _notifyOrderStatusChange(
      String orderId, OrderStatus newStatus) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      final userId = orderDoc.data()?['userId'] as String?;
      if (userId == null || userId.isEmpty) return;

      final label = _statusLabel(newStatus);
      await NotificationController.sendToUser(
        userId: userId,
        title: 'Order $label',
        body: 'Your order #${orderId.substring(0, 8).toUpperCase()} is now ${label.toLowerCase()}.',
        type: NotificationType.order,
        orderId: orderId,
      );
    } catch (_) {
      // Non-fatal: don't block the status update on notification failure.
    }
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.packed:
        return 'Packed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Decrements product stock for every item in [orderId] once the order is
  /// delivered. Guarded by a `stockDeducted` flag so re-marking an order as
  /// delivered never double-counts.
  Future<void> _reduceStockForOrder(String orderId) async {
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) return;

    final orderData = orderDoc.data() ?? {};
    if (orderData['stockDeducted'] == true) return;

    final items = (orderData['items'] as List<dynamic>?) ?? [];
    for (final item in items) {
      if (item is! Map) continue;
      final productId = item['productId'] as String?;
      final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
      if (productId == null || productId.isEmpty || quantity <= 0) continue;

      final productRef = _firestore.collection('products').doc(productId);
      await _firestore.runTransaction((txn) async {
        final snap = await txn.get(productRef);
        if (!snap.exists) return;
        final currentStock = (snap.data()?['stock'] as num?)?.toInt() ?? 0;
        final newStock = (currentStock - quantity).clamp(0, 999999);
        txn.update(productRef, {
          'stock': newStock,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      });
    }
  }

  Future<void> updateOrderTracking(
      String orderId, String trackingNumber) async {
    try {
      _error = null;
      await _firestore.collection('orders').doc(orderId).update({
        'trackingNumber': trackingNumber,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await loadOrders();
      notifyListeners();
    } catch (e) {
      _error = 'Error updating tracking: ${e.toString()}';
      notifyListeners();
    }
  }

  // ============ USER MANAGEMENT METHODS ============

  Future<void> loadUsers() async {
    try {
      _usersLoading = true;
      _error = null;
      notifyListeners();

      // Load users and all orders in parallel.
      final results = await Future.wait([
        _firestore
            .collection('users')
            .where('role', isNotEqualTo: 'admin')
            .get(),
        _firestore.collection('orders').get(),
      ]);

      final usersSnapshot = results[0];
      final ordersSnapshot = results[1];

      // Aggregate per-user totals from actual orders.
      final Map<String, int> orderCounts = {};
      final Map<String, double> orderTotals = {};
      for (final doc in ordersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final uid = data['userId'] as String? ?? '';
        if (uid.isEmpty) continue;
        // Exclude cancelled orders from total spent.
        final status = data['status'] as String? ?? '';
        orderCounts[uid] = (orderCounts[uid] ?? 0) + 1;
        if (status != 'cancelled') {
          final price = (data['totalPrice'] ?? 0.0);
          orderTotals[uid] = (orderTotals[uid] ?? 0.0) +
              (price is num ? price.toDouble() : 0.0);
        }
      }

      _users = usersSnapshot.docs.map((doc) {
        final base = AdminUserModel.fromJson(doc.data(), doc.id);
        return AdminUserModel(
          uid: base.uid,
          name: base.name,
          email: base.email,
          phone: base.phone,
          isDisabled: base.isDisabled,
          isAdmin: base.isAdmin,
          createdAt: base.createdAt,
          lastLogin: base.lastLogin,
          totalOrders: orderCounts[base.uid] ?? 0,
          totalSpent: orderTotals[base.uid] ?? 0.0,
        );
      }).toList();

      _usersLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading users: ${e.toString()}';
      _usersLoading = false;
      notifyListeners();
    }
  }

  Future<void> disableUser(String userId) async {
    try {
      _error = null;
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'isDisabled': true});
      await loadUsers();
      notifyListeners();
    } catch (e) {
      _error = 'Error disabling user: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> enableUser(String userId) async {
    try {
      _error = null;
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'isDisabled': false});
      await loadUsers();
      notifyListeners();
    } catch (e) {
      _error = 'Error enabling user: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      _error = null;
      await _firestore.collection('users').doc(userId).delete();
      await loadUsers();
      notifyListeners();
    } catch (e) {
      _error = 'Error deleting user: ${e.toString()}';
      notifyListeners();
    }
  }

  // ============ UTILITY METHODS ============

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadAllAdminData() async {
    await Future.wait([
      loadDashboardStats(),
      loadProducts(),
      loadOrders(),
      loadUsers(),
    ]);
  }
}
