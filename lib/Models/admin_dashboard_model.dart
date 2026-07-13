import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardStats {
  final int totalUsers;
  final int totalOrders;
  final int totalProducts;
  final double revenue;
  final int pendingOrders;
  final int activeProducts;
  final DateTime lastUpdated;

  AdminDashboardStats({
    required this.totalUsers,
    required this.totalOrders,
    required this.totalProducts,
    required this.revenue,
    required this.pendingOrders,
    required this.activeProducts,
    required this.lastUpdated,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      revenue: _toDouble(json['revenue']),
      pendingOrders: json['pendingOrders'] ?? 0,
      activeProducts: json['activeProducts'] ?? 0,
      lastUpdated: _toDateTime(json['lastUpdated']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalOrders': totalOrders,
      'totalProducts': totalProducts,
      'revenue': revenue,
      'pendingOrders': pendingOrders,
      'activeProducts': activeProducts,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
