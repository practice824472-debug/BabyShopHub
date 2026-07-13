import 'package:cloud_firestore/cloud_firestore.dart';

enum CouponType { percentage, fixed }

class CouponModel {
  final String couponId;
  final String code;
  final CouponType type;
  final double value;
  final DateTime? expiryDate;
  final int usageLimit; // 0 = unlimited
  final List<String> usedBy;
  final bool isActive;
  final DateTime createdAt;

  CouponModel({
    required this.couponId,
    required this.code,
    required this.type,
    required this.value,
    this.expiryDate,
    this.usageLimit = 0,
    this.usedBy = const [],
    this.isActive = true,
    required this.createdAt,
  });

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  bool get isUsageExhausted =>
      usageLimit > 0 && usedBy.length >= usageLimit;

  bool get isValid => isActive && !isExpired && !isUsageExhausted;

  double discountFor(double subtotal) {
    if (type == CouponType.percentage) {
      return (subtotal * value / 100).clamp(0, subtotal);
    }
    return value.clamp(0, subtotal);
  }

  factory CouponModel.fromJson(Map<String, dynamic> json, String couponId) {
    return CouponModel(
      couponId: couponId,
      code: (json['code'] ?? '').toString().toUpperCase(),
      type: (json['type'] == 'fixed') ? CouponType.fixed : CouponType.percentage,
      value: _toDouble(json['value']),
      expiryDate: _toDateTime(json['expiryDate']),
      usageLimit: _toInt(json['usageLimit']),
      usedBy: (json['usedBy'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isActive: json['isActive'] ?? true,
      createdAt: _toDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code.toUpperCase(),
      'type': type == CouponType.fixed ? 'fixed' : 'percentage',
      'value': value,
      'expiryDate': expiryDate?.toIso8601String(),
      'usageLimit': usageLimit,
      'usedBy': usedBy,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
