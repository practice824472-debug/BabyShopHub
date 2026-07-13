import 'package:cloud_firestore/cloud_firestore.dart';

// ──────────────────────────────────────────────
// Address
// ──────────────────────────────────────────────
class OrderAddress {
  final String fullName;
  final String phone;
  final String addressLine;
  final String city;
  final String postalCode;

  const OrderAddress({
    required this.fullName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.postalCode,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phone': phone,
        'addressLine': addressLine,
        'city': city,
        'postalCode': postalCode,
      };

  factory OrderAddress.fromJson(Map<String, dynamic> json) => OrderAddress(
        fullName: json['fullName'] ?? '',
        phone: json['phone'] ?? '',
        addressLine: json['addressLine'] ?? '',
        city: json['city'] ?? '',
        postalCode: json['postalCode'] ?? '',
      );

  String get formatted =>
      '$addressLine, $city $postalCode';
}

// ──────────────────────────────────────────────
// Order Item (snapshot of cart item at purchase)
// ──────────────────────────────────────────────
class OrderItem {
  final String productId;
  final String name;
  final String brand;
  final String image;
  final double price;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.brand,
    required this.image,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        // Also stored as productName/subtotal so the admin order views (which
        // read those keys) can display item names and line totals.
        'productName': name,
        'brand': brand,
        'image': image,
        'price': price,
        'quantity': quantity,
        'subtotal': subtotal,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['productId'] ?? '',
        name: json['name'] ?? '',
        brand: json['brand'] ?? '',
        image: json['image'] ?? '',
        price: (json['price'] ?? 0).toDouble(),
        quantity: json['quantity'] ?? 1,
      );
}

// ──────────────────────────────────────────────
// Order Status
// ──────────────────────────────────────────────
enum OrderStatus {
  pending,
  confirmed,
  packed,
  shipped,
  outForDelivery,
  delivered,
  cancelled;

  String get label {
    switch (this) {
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

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

// ──────────────────────────────────────────────
// Order Model
// ──────────────────────────────────────────────
class OrderModel {
  final String orderId;
  final String userId;
  final List<OrderItem> items;
  final OrderAddress address;
  final String paymentMethod;
  final OrderStatus status;
  final double totalPrice;
  final DateTime createdAt;

  const OrderModel({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.address,
    required this.paymentMethod,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'userId': userId,
        'items': items.map((i) => i.toJson()).toList(),
        'address': address.toJson(),
        'paymentMethod': paymentMethod,
        'status': status.name,
        'totalPrice': totalPrice,
        'createdAt': createdAt.toIso8601String(),
      };

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        orderId: json['orderId'] ?? '',
        userId: json['userId'] ?? '',
        items: (json['items'] as List? ?? [])
            .map((i) => OrderItem.fromJson(Map<String, dynamic>.from(i as Map)))
            .toList(),
        address: OrderAddress.fromJson(
            Map<String, dynamic>.from(json['address'] as Map? ?? {})),
        paymentMethod: json['paymentMethod'] ?? 'Cash on Delivery',
        status: OrderStatus.fromString(json['status'] ?? 'pending'),
        totalPrice: (json['totalPrice'] ?? 0).toDouble(),
        createdAt: json['createdAt'] is Timestamp
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
                DateTime.now(),
      );
}
