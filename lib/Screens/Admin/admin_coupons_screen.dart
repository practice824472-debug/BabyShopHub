import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Controllers/coupon_controller.dart';
import '../../Models/coupon_model.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CouponController>().loadCoupons());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coupon Management'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCouponDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<CouponController>(
        builder: (context, controller, _) {
          if (controller.coupons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No coupons yet',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('Tap + to create your first coupon.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: controller.coupons.length,
            itemBuilder: (context, index) {
              final coupon = controller.coupons[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: coupon.isValid
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    child: Icon(
                      Icons.local_offer,
                      color: coupon.isValid ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(coupon.code,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    coupon.type == CouponType.percentage
                        ? '${coupon.value.toStringAsFixed(0)}% off'
                        : '\$${coupon.value.toStringAsFixed(2)} off'
                        '${coupon.expiryDate != null ? ' • expires ${_fmt(coupon.expiryDate!)}' : ''}'
                        '${coupon.usageLimit > 0 ? ' • ${coupon.usedBy.length}/${coupon.usageLimit} used' : ''}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: coupon.isActive,
                        onChanged: (_) => controller.toggleActive(coupon),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _showCouponDialog(context, coupon: coupon),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, controller, coupon),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void _confirmDelete(
      BuildContext context, CouponController controller, CouponModel coupon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Coupon?'),
        content: Text('Delete coupon "${coupon.code}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.deleteCoupon(coupon.couponId);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCouponDialog(BuildContext context, {CouponModel? coupon}) {
    final codeController = TextEditingController(text: coupon?.code ?? '');
    final valueController =
        TextEditingController(text: coupon?.value.toString() ?? '');
    final usageLimitController =
        TextEditingController(text: coupon?.usageLimit.toString() ?? '0');
    CouponType type = coupon?.type ?? CouponType.percentage;
    DateTime? expiryDate = coupon?.expiryDate;
    final controller = context.read<CouponController>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(coupon == null ? 'Create Coupon' : 'Edit Coupon'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Coupon Code'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CouponType>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Discount Type'),
                  items: const [
                    DropdownMenuItem(
                        value: CouponType.percentage, child: Text('Percentage (%)')),
                    DropdownMenuItem(
                        value: CouponType.fixed, child: Text('Fixed Amount (\$)')),
                  ],
                  onChanged: (v) => setDialogState(() => type = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: type == CouponType.percentage
                        ? 'Percentage Off'
                        : 'Amount Off',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usageLimitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Usage Limit (0 = unlimited)'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(expiryDate == null
                      ? 'No Expiry Date'
                      : 'Expires: ${_fmt(expiryDate!)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: expiryDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setDialogState(() => expiryDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final code = codeController.text.trim().toUpperCase();
                final value = double.tryParse(valueController.text) ?? 0;
                final usageLimit = int.tryParse(usageLimitController.text) ?? 0;
                if (code.isEmpty || value <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Enter a valid code and value.')));
                  return;
                }
                final model = CouponModel(
                  couponId: coupon?.couponId ?? '',
                  code: code,
                  type: type,
                  value: value,
                  expiryDate: expiryDate,
                  usageLimit: usageLimit,
                  usedBy: coupon?.usedBy ?? const [],
                  isActive: coupon?.isActive ?? true,
                  createdAt: coupon?.createdAt ?? DateTime.now(),
                );
                final ok = coupon == null
                    ? await controller.createCoupon(model)
                    : await controller.updateCoupon(coupon.couponId, model);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok
                        ? 'Coupon saved successfully.'
                        : (controller.error ?? 'Failed to save coupon.')),
                  ));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
