import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../Controllers/order_controller.dart';
import '../../Models/order_model.dart';
import '../../Utils/app_theme.dart';
import '../../Widgets/shimmer_widgets.dart';
import 'order_status_badge.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<OrderController>().fetchUserOrders(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<OrderController>().fetchUserOrders(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<OrderController>(
        builder: (context, ctrl, _) {
          if (ctrl.isFetching) {
            return const ShimmerList();
          }

          if (ctrl.error != null) {
            return _ErrorState(
              message: ctrl.error!,
              onRetry: ctrl.fetchUserOrders,
            );
          }

          if (ctrl.orders.isEmpty) {
            return _EmptyState();
          }

          return RefreshIndicator(
            onRefresh: ctrl.fetchUserOrders,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ctrl.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _OrderCard(order: ctrl.orders[index])
                    .animate()
                    .fadeIn(duration: 250.ms)
                    .slideY(begin: 0.05, end: 0);
              },
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Order Card
// ──────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final shortId = shortOrderId(order.orderId);
    final date = _formatDate(order.createdAt);
    final itemSummary = order.items.isEmpty
        ? 'No items'
        : order.items.length == 1
            ? order.items.first.name
            : '${order.items.first.name} + ${order.items.length - 1} more';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(orderId: order.orderId),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──
              Row(
                children: [
                  Text(
                    shortId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 8),

              // ── Item summary ──
              Text(
                itemSummary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '${order.items.length} item${order.items.length == 1 ? '' : 's'}  •  $date',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),

              // ── Footer row ──
              Row(
                children: [
                  Icon(
                    order.paymentMethod == 'Cash on Delivery'
                        ? Icons.money
                        : Icons.credit_card,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.paymentMethod,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    '\$${order.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Track order',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_ios,
                      size: 12, color: AppTheme.primaryColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ──────────────────────────────────────────────
// Empty / Error states
// ──────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No orders yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Your order history will appear here once you place your first order.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Couldn\'t load orders',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
