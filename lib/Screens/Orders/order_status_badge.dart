import 'package:flutter/material.dart';

import '../../Models/order_model.dart';
import '../../Utils/app_theme.dart';

/// Public, reusable status badge used across Orders screens.
class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case OrderStatus.pending:
        return AppTheme.warningColor;
      case OrderStatus.confirmed:
      case OrderStatus.packed:
        return AppTheme.infoColor;
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        return AppTheme.primaryColor;
      case OrderStatus.delivered:
        return AppTheme.successColor;
      case OrderStatus.cancelled:
        return AppTheme.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Shortens an order ID to 8 chars safely (pads if shorter).
String shortOrderId(String orderId) {
  final id = orderId.length >= 8 ? orderId.substring(0, 8) : orderId;
  return '#${id.toUpperCase()}';
}
