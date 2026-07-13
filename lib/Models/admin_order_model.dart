import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double subtotal;

  AdminOrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory AdminOrderItem.fromJson(Map<String, dynamic> json) {
    return AdminOrderItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? 'N/A',
      quantity: _toInt(json['quantity']),
      price: _toDouble(json['price']),
      subtotal: _toDouble(json['subtotal']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }
}

// Must match OrderStatus in order_model.dart exactly so Firestore strings align
enum OrderStatus {
  pending,
  confirmed,
  packed,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
}

class AdminOrderModel {
  final String orderId;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final List<AdminOrderItem> items;
  final double totalPrice;
  final String paymentMethod;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String? shippingAddress;
  final String? trackingNumber;

  AdminOrderModel({
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhone = '',
    required this.items,
    required this.totalPrice,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.deliveredAt,
    this.shippingAddress,
    this.trackingNumber,
  });

  factory AdminOrderModel.fromJson(Map<String, dynamic> json, String orderId) {
    return AdminOrderModel(
      orderId: orderId,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'N/A',
      userEmail: json['userEmail'] ?? 'N/A',
      userPhone: json['userPhone'] ?? '',
      items: (json['items'] as List?)
          ?.map((item) => AdminOrderItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList() ??
          [],
      totalPrice: _toDouble(json['totalPrice']),
      paymentMethod: json['paymentMethod'] ?? 'N/A',
      status: _parseOrderStatus(json['status']),
      createdAt: _toDateTime(json['createdAt']) ?? DateTime.now(),
      deliveredAt: _toDateTime(json['deliveredAt']),
      shippingAddress: json['shippingAddress'],
      trackingNumber: json['trackingNumber'],
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'items': items.map((item) => item.toJson()).toList(),
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'status': _statusToString(status),
      'createdAt': createdAt.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'shippingAddress': shippingAddress,
      'trackingNumber': trackingNumber,
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static OrderStatus _parseOrderStatus(String? statusStr) {
    return OrderStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => OrderStatus.pending,
    );
  }

  static String _statusToString(OrderStatus status) => status.name;

  String get statusDisplayString {
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
}
