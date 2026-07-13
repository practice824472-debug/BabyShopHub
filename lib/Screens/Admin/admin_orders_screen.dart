import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Controllers/admin_controller.dart';
import '../../Models/admin_order_model.dart';


class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  OrderStatus? _selectedFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AdminController>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: Consumer<AdminController>(
        builder: (context, adminController, _) {
          if (adminController.ordersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<AdminOrderModel> filteredOrders = adminController.orders;
          if (_selectedFilter != null) {
            filteredOrders = adminController.orders
                .where((order) => order.status == _selectedFilter)
                .toList();
          }

          if (filteredOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Orders Found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Filter Chips
              Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Confirmed'),
                        selected: _selectedFilter == OrderStatus.confirmed,
                        onSelected: (_) {
                          setState(() {
                            _selectedFilter = OrderStatus.confirmed;
                          });
                        },
                      ),

                      FilterChip(
                        label: const Text('Packed'),
                        selected: _selectedFilter == OrderStatus.packed,
                        onSelected: (_) {
                          setState(() {
                            _selectedFilter = OrderStatus.packed;
                          });
                        },
                      ),

                      FilterChip(
                        label: const Text('Shipped'),
                        selected: _selectedFilter == OrderStatus.shipped,
                        onSelected: (_) {
                          setState(() {
                            _selectedFilter = OrderStatus.shipped;
                          });
                        },
                      ),

                      FilterChip(
                        label: const Text('Out for Delivery'),
                        selected: _selectedFilter == OrderStatus.outForDelivery,
                        onSelected: (_) {
                          setState(() {
                            _selectedFilter = OrderStatus.outForDelivery;
                          });
                        },
                      ),

                      FilterChip(
                        label: const Text('Delivered'),
                        selected: _selectedFilter == OrderStatus.delivered,
                        onSelected: (_) {
                          setState(() {
                            _selectedFilter = OrderStatus.delivered;
                          });
                        },
                      ),

                      FilterChip(
                        label: const Text('Cancelled'),
                        selected: _selectedFilter == OrderStatus.cancelled,
                        onSelected: (_) {
                          setState(() {
                            _selectedFilter = OrderStatus.cancelled;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Orders List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return _buildOrderCard(context, order, adminController);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, AdminOrderModel order,
      AdminController adminController) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.orderId.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.userName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.statusDisplayString,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(order.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            // Order Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.items.length} items',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${order.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(order.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.info_outline,
                  label: 'Details',
                  color: Colors.blue,
                  onTap: () {
                    _showOrderDetailsDialog(context, order);
                  },
                ),
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Update Status',
                  color: Colors.orange,
                  onTap: () {
                    _showStatusUpdateDialog(context, order, adminController);
                  },
                ),
                _buildActionButton(
                  icon: Icons.local_shipping,
                  label: 'Tracking',
                  color: Colors.purple,
                  onTap: () {
                    _showTrackingDialog(context, order, adminController);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderDetailsDialog(BuildContext context, AdminOrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order.orderId.substring(0, 8).toUpperCase()}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Customer:', order.userName),
              _buildDetailRow('Email:', order.userEmail),
              _buildDetailRow(
                'Phone:',
                order.userPhone.isNotEmpty ? order.userPhone : 'N/A',
              ),
              _buildDetailRow(
                'Address:',
                (order.shippingAddress?.isNotEmpty ?? false)
                    ? order.shippingAddress!
                    : 'N/A',
              ),
              _buildDetailRow('Date:', _formatDate(order.createdAt)),
              _buildDetailRow('Status:', order.statusDisplayString),
              _buildDetailRow('Payment Method:', order.paymentMethod),
              _buildDetailRow(
                'Total:',
                '\$${order.totalPrice.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 16),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Qty: ${item.quantity} × \$${item.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(BuildContext context, AdminOrderModel order,
      AdminController adminController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: OrderStatus.values.map((status) {
              return RadioListTile<OrderStatus>(
                title: Text(_statusLabel(status)),
                value: status,
                groupValue: order.status,
                onChanged: (value) {
                  if (value != null) {
                    adminController.updateOrderStatus(order.orderId, value);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Status updated to ${_statusLabel(value)}'),
                      ),
                    );
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTrackingDialog(BuildContext context, AdminOrderModel order,
      AdminController adminController) {
    final trackingController =
        TextEditingController(text: order.trackingNumber ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Tracking Number'),
        content: TextField(
          controller: trackingController,
          decoration: InputDecoration(
            labelText: 'Tracking Number',
            hintText: 'e.g., FX123456789',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (trackingController.text.isNotEmpty) {
                adminController.updateOrderTracking(
                  order.orderId,
                  trackingController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tracking number updated successfully'),
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;

      case OrderStatus.confirmed:
        return Colors.blue;

      case OrderStatus.packed:
        return Colors.indigo;

      case OrderStatus.shipped:
        return Colors.purple;

      case OrderStatus.outForDelivery:
        return Colors.deepOrange;

      case OrderStatus.delivered:
        return Colors.green;

      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return "Pending";

      case OrderStatus.confirmed:
        return "Confirmed";

      case OrderStatus.packed:
        return "Packed";

      case OrderStatus.shipped:
        return "Shipped";

      case OrderStatus.outForDelivery:
        return "Out for Delivery";

      case OrderStatus.delivered:
        return "Delivered";

      case OrderStatus.cancelled:
        return "Cancelled";
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
