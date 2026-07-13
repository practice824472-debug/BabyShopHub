import 'package:flutter/material.dart';

import '../../Models/order_model.dart';
import '../../Utils/app_theme.dart';
import 'checkout_widgets.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final OrderModel order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent back navigation — order is already placed
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order Confirmed'),
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            CheckoutStepIndicator(current: 3),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // ── Success icon ──
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 70,
                        color: AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Order Placed!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thank you for shopping with BabyShop.\nWe\'ll notify you when your order ships.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),

                    // ── Order ID card ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tag,
                              color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Order ID',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              '#${order.orderId.substring(0, 8).toUpperCase()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Items summary ──
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Items Ordered',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ...order.items.map(
                              (item) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.name} × ${item.quantity}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    Text(
                                      '\$${item.subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                const Text('Total Paid',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text(
                                  '\$${order.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppTheme.successColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Delivery info ──
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.local_shipping_outlined,
                            color: AppTheme.primaryColor),
                        title: const Text('Delivery Address'),
                        subtitle: Text(
                          '${order.address.fullName}\n'
                          '${order.address.formatted}',
                        ),
                        isThreeLine: true,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Payment method ──
                    Card(
                      child: ListTile(
                        leading: Icon(
                          order.paymentMethod == 'Cash on Delivery'
                              ? Icons.money
                              : Icons.credit_card,
                          color: AppTheme.primaryColor,
                        ),
                        title: const Text('Payment Method'),
                        subtitle: Text(order.paymentMethod),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Status ──
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.pending_outlined,
                            color: AppTheme.warningColor),
                        title: const Text('Order Status'),
                        subtitle: Text(order.status.label),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Bottom CTA ──
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Continue Shopping'),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/user-home',
                        (route) => false,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
