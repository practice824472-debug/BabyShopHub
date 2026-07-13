import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Models/cart_model.dart';
import '../Models/product_model.dart';

class CartController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _items.isEmpty;

  // Total number of units across all items (used for the cart badge).
  int get itemCount =>
      _items.fold(0, (total, item) => total + item.quantity);

  // Number of distinct products in the cart.
  int get distinctItemCount => _items.length;

  double get subtotal =>
      _items.fold(0, (total, item) => total + item.subtotal);

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _cartDoc {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('carts').doc(uid);
  }

  int quantityOf(String productId) {
    for (final item in _items) {
      if (item.productId == productId) return item.quantity;
    }
    return 0;
  }

  /// Sets the quantity of an existing cart item to an exact value.
  /// If the product is not in the cart, adds it. Removes it if [quantity] <= 0.
  Future<void> setQuantity(ProductModel product, int quantity) async {
    if (quantity <= 0) {
      await removeItem(product.productId);
      return;
    }
    final clamped = quantity.clamp(1, product.stock).toInt();
    final index =
        _items.indexWhere((item) => item.productId == product.productId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: clamped);
    } else {
      _items.add(CartItem(
        productId: product.productId,
        name: product.name,
        brand: product.brand,
        image: product.image,
        price: product.price,
        stock: product.stock,
        quantity: clamped,
      ));
    }
    notifyListeners();
    await _persist();
  }

  Future<void> loadCart() async {
    final doc = _cartDoc;
    if (doc == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await doc.get();
      final data = snapshot.data();
      _items
        ..clear()
        ..addAll(
          (data?['items'] as List?)
                  ?.map((item) =>
                      CartItem.fromJson(Map<String, dynamic>.from(item as Map)))
                  .toList() ??
              [],
        );
    } catch (e) {
      _error = 'Error loading cart: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(ProductModel product, {int quantity = 1}) async {
    final index =
        _items.indexWhere((item) => item.productId == product.productId);

    if (index >= 0) {
      final existing = _items[index];
      final newQuantity =
          (existing.quantity + quantity).clamp(1, product.stock).toInt();
      _items[index] = existing.copyWith(quantity: newQuantity);
    } else {
      _items.add(
        CartItem(
          productId: product.productId,
          name: product.name,
          brand: product.brand,
          image: product.image,
          price: product.price,
          stock: product.stock,
          quantity: quantity.clamp(1, product.stock).toInt(),
        ),
      );
    }

    notifyListeners();
    await _persist();
  }

  Future<void> incrementQuantity(String productId) async {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index < 0) return;

    final item = _items[index];
    if (item.quantity >= item.stock) return;
    _items[index] = item.copyWith(quantity: item.quantity + 1);

    notifyListeners();
    await _persist();
  }

  Future<void> decrementQuantity(String productId) async {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index < 0) return;

    final item = _items[index];
    if (item.quantity <= 1) {
      await removeItem(productId);
      return;
    }
    _items[index] = item.copyWith(quantity: item.quantity - 1);

    notifyListeners();
    await _persist();
  }

  Future<void> removeItem(String productId) async {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();
    await _persist();
  }

  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final doc = _cartDoc;
    if (doc == null) return;

    try {
      _error = null;
      await doc.set({
        'userId': _uid,
        'items': _items.map((item) => item.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _error = 'Error saving cart: ${e.toString()}';
      notifyListeners();
    }
  }
}
