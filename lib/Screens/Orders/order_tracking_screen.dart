import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Controllers/order_controller.dart';
import '../../Models/order_model.dart';
import '../../Services/invoice_service.dart';
import '../../Utils/app_theme.dart';
import '../../Widgets/shimmer_widgets.dart';
import 'order_status_badge.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  static const _timeline = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.packed,
    OrderStatus.shipped,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final stream = context.read<OrderController>().streamOrder(orderId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${shortOrderId(orderId)}'),
        actions: [
          StreamBuilder<OrderModel>(
            stream: stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Download Invoice',
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: () => _shareInvoice(context, snapshot.data!),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<OrderModel>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerList(itemCount: 4);
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Could not load order details.'));
          }

          final order = snapshot.data!;
          final isCancelled = order.status == OrderStatus.cancelled;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status banner ──
                _StatusBanner(status: order.status, isCancelled: isCancelled),
                const SizedBox(height: 16),

                // ── Tracking timeline ──
                if (!isCancelled) ...[
                _SectionHeader('Tracking'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    child: _Timeline(
                      steps: _timeline,
                      current: order.status,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Order items ──
              _SectionHeader('Items (${order.items.length})'),
              Card(
                child: Column(
                  children: [
                    ...order.items.asMap().entries.map((entry) {
                      final isLast = entry.key == order.items.length - 1;
                      return Column(
                        children: [
                          _ItemRow(item: entry.value),
                          if (!isLast)
                            const Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16),
                        ],
                      );
                    }),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Text('Total Paid',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text(
                            '\$${order.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Delivery info ──
              _SectionHeader('Delivery Address'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppTheme.primaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.address.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(order.address.phone),
                            Text(order.address.addressLine),
                            Text(
                                '${order.address.city} ${order.address.postalCode}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Payment ──
              _SectionHeader('Payment'),
              Card(
                child: ListTile(
                  leading: Icon(
                    order.paymentMethod == 'Cash on Delivery'
                        ? Icons.money
                        : Icons.credit_card,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text(order.paymentMethod),
                  subtitle: const Text('Payment method'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _shareInvoice(context, order),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Download Invoice'),
                ),
              ),
              const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _shareInvoice(BuildContext context, OrderModel order) async {
    try {
      await InvoiceService.shareInvoice(order);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate invoice: $e')),
      );
    }
  }
}

// ──────────────────────────────────────────────
// Status Banner
// ──────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final OrderStatus status;
  final bool isCancelled;

  const _StatusBanner({required this.status, required this.isCancelled});

  Color get _bg => isCancelled
      ? AppTheme.errorColor.withValues(alpha: 0.08)
      : AppTheme.primaryColor.withValues(alpha: 0.06);

  IconData get _icon =>
      isCancelled ? Icons.cancel_outlined : Icons.local_shipping_outlined;

  Color get _iconColor =>
      isCancelled ? AppTheme.errorColor : AppTheme.primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _iconColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(_icon, color: _iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Status',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                OrderStatusBadge(status: status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Timeline
// ──────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  final List<OrderStatus> steps;
  final OrderStatus current;

  const _Timeline({required this.steps, required this.current});

  @override
  Widget build(BuildContext context) {
    final currentIndex = steps.indexOf(current);
    return Column(
      children: steps.asMap().entries.map((entry) {
        final idx = entry.key;
        final step = entry.value;
        return _TimelineRow(
          label: step.label,
          isDone: idx < currentIndex,
          isActive: idx == currentIndex,
          isLast: idx == steps.length - 1,
        );
      }).toList(),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isActive;
  final bool isLast;

  const _TimelineRow({
    required this.label,
    required this.isDone,
    required this.isActive,
    required this.isLast,
  });

  Color get _dotColor {
    if (isDone) return AppTheme.successColor;
    if (isActive) return AppTheme.primaryColor;
    return Colors.grey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: _dotColor),
                  child: isDone
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : isActive
                      ? const Icon(Icons.circle,
                      size: 10, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDone
                          ? AppTheme.successColor
                          : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? AppTheme.primaryColor
                    : isDone
                    ? AppTheme.textPrimaryColor
                    : Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Item Row
// ──────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final OrderItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: item.image.isEmpty
                  ? Container(
                  color: Colors.grey.shade100,
                  child: Icon(Icons.image, color: Colors.grey.shade400))
                  : CachedNetworkImage(
                imageUrl: item.image,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: Colors.grey.shade100),
                errorWidget: (_, __, ___) => Icon(
                    Icons.image_not_supported,
                    color: Colors.grey.shade400),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (item.brand.isNotEmpty)
                  Text(item.brand,
                      style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Qty: ${item.quantity}',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Section Header
// ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
