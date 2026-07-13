import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Controllers/cart_controller.dart';
import '../../Controllers/coupon_controller.dart';
import '../../Controllers/order_controller.dart';
import '../../Controllers/payment_controller.dart';
import '../../Models/card_model.dart';
import '../../Models/order_model.dart';
import '../../Utils/app_theme.dart';
import '../../Utils/card_form_fields.dart';
import 'checkout_widgets.dart';
import 'order_confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  final OrderAddress address;

  const PaymentScreen({super.key, required this.address});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'Cash on Delivery'; // or 'Card'

  // Which saved card (if any) is currently selected at checkout.
  String? _selectedCardId;
  // True once the user chooses to type in a brand-new card instead of
  // using one of their saved ones.
  bool _useNewCard = false;

  // Card form controllers
  final _cardNumberCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _cardFormKey = GlobalKey<FormState>();

  final _couponCtrl = TextEditingController();
  bool _applyingCoupon = false;
  String? _couponError;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final paymentCtrl = context.read<PaymentController>();
      await paymentCtrl.fetchSavedCards();
      if (!mounted) return;
      if (paymentCtrl.savedCards.isNotEmpty) {
        setState(() {
          _selectedCardId =
              paymentCtrl.defaultCard?.cardId ?? paymentCtrl.savedCards.first.cardId;
        });
      }
    });
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _cardNameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final cart = context.read<CartController>();
    final coupon = context.read<CouponController>();
    setState(() {
      _applyingCoupon = true;
      _couponError = null;
    });
    final error = await coupon.applyCoupon(_couponCtrl.text, cart.subtotal);
    if (!mounted) return;
    setState(() {
      _applyingCoupon = false;
      _couponError = error;
    });
  }

  Future<void> _placeOrder() async {
    final paymentCtrl = context.read<PaymentController>();
    final usingSavedCard = _method == 'Card' &&
        !_useNewCard &&
        paymentCtrl.savedCards.isNotEmpty &&
        _selectedCardId != null;

    if (_method == 'Card' && !usingSavedCard) {
      if (!_cardFormKey.currentState!.validate()) return;
    }

    final cart = context.read<CartController>();
    final orderCtrl = context.read<OrderController>();
    final couponCtrl = context.read<CouponController>();

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
      );
      return;
    }

    String paymentMethod = _method;
    if (_method == 'Card') {
      if (usingSavedCard) {
        final card = paymentCtrl.savedCards
            .firstWhere((c) => c.cardId == _selectedCardId);
        paymentMethod = 'Card (${card.maskedCardNumber})';
      } else {
        final last4 = _cardNumberCtrl.text.replaceAll(' ', '');
        paymentMethod = 'Card (**** ${last4.substring(last4.length - 4)})';
      }
    }

    final discount = couponCtrl.discountAmount(cart.subtotal);
    final finalTotal = (cart.subtotal - discount).clamp(0, double.infinity);

    try {
      final order = await orderCtrl.placeOrder(
        cartItems: cart.items.toList(),
        address: widget.address,
        paymentMethod: paymentMethod,
        totalPrice: finalTotal.toDouble(),
      );

      if (couponCtrl.appliedCoupon != null) {
        await couponCtrl.markCouponUsed();
      }

      // Clear cart after successful order
      await cart.clearCart();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(order: order),
        ),
            (route) => route.settings.name == '/user-home' || route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final orderCtrl = context.watch<OrderController>();
    final paymentCtrl = context.watch<PaymentController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Column(
        children: [
          CheckoutStepIndicator(current: 2),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Delivery address summary ──
                  _SectionCard(
                    icon: Icons.location_on_outlined,
                    title: 'Delivering to',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.address.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(widget.address.phone,
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text(widget.address.formatted,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Order summary ──
                  Consumer<CouponController>(
                    builder: (context, couponCtrl, _) {
                      final discount = couponCtrl.discountAmount(cart.subtotal);
                      final total = (cart.subtotal - discount)
                          .clamp(0, double.infinity)
                          .toDouble();
                      return _SectionCard(
                        icon: Icons.receipt_long_outlined,
                        title: 'Order Summary',
                        child: Column(
                          children: [
                            ...cart.items.map(
                                  (item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.name} × ${item.quantity}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '\$${item.subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _couponCtrl,
                                    textCapitalization: TextCapitalization.characters,
                                    enabled: couponCtrl.appliedCoupon == null,
                                    decoration: InputDecoration(
                                      labelText: 'Coupon code',
                                      isDense: true,
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (couponCtrl.appliedCoupon != null)
                                  OutlinedButton(
                                    onPressed: () {
                                      couponCtrl.removeAppliedCoupon();
                                      _couponCtrl.clear();
                                      setState(() => _couponError = null);
                                    },
                                    child: const Text('Remove'),
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: _applyingCoupon ? null : _applyCoupon,
                                    child: _applyingCoupon
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : const Text('Apply'),
                                  ),
                              ],
                            ),
                            if (_couponError != null) ...[
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _couponError!,
                                  style: const TextStyle(
                                      color: AppTheme.errorColor, fontSize: 12),
                                ),
                              ),
                            ],
                            if (couponCtrl.appliedCoupon != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.local_offer_outlined,
                                      size: 16, color: AppTheme.successColor),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${couponCtrl.appliedCoupon!.code} applied',
                                      style: const TextStyle(
                                          color: AppTheme.successColor,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Text('-\$${discount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          color: AppTheme.successColor,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                            const Divider(height: 20),
                            Row(
                              children: [
                                const Text('Total',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text(
                                  '\$${total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppTheme.successColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Payment method ──
                  Text(
                    'Payment Method',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  _PaymentOption(
                    value: 'Cash on Delivery',
                    groupValue: _method,
                    icon: Icons.money,
                    label: 'Cash on Delivery',
                    subtitle: 'Pay when your order arrives',
                    onChanged: (v) => setState(() => _method = v!),
                  ),
                  const SizedBox(height: 8),
                  _PaymentOption(
                    value: 'Card',
                    groupValue: _method,
                    icon: Icons.credit_card,
                    label: 'Debit / Credit Card',
                    subtitle: 'Visa, Mastercard accepted',
                    onChanged: (v) => setState(() => _method = v!),
                  ),

                  // ── Card selection (shown only if Card selected) ──
                  if (_method == 'Card') ...[
                    const SizedBox(height: 16),
                    if (paymentCtrl.savedCards.isNotEmpty && !_useNewCard) ...[
                      ...paymentCtrl.savedCards.map(
                        (card) => _SavedCardOption(
                          card: card,
                          selected: card.cardId == _selectedCardId,
                          onTap: () =>
                              setState(() => _selectedCardId = card.cardId),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => setState(() {
                          _useNewCard = true;
                          _selectedCardId = null;
                        }),
                        icon: const Icon(Icons.add),
                        label: const Text('Use a new card'),
                      ),
                    ] else ...[
                      if (paymentCtrl.savedCards.isNotEmpty) ...[
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _useNewCard = false;
                            _selectedCardId = paymentCtrl.defaultCard?.cardId ??
                                paymentCtrl.savedCards.first.cardId;
                          }),
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Use a saved card instead'),
                        ),
                        const SizedBox(height: 4),
                      ],
                      _CardForm(
                        formKey: _cardFormKey,
                        cardNumberCtrl: _cardNumberCtrl,
                        cardNameCtrl: _cardNameCtrl,
                        expiryCtrl: _expiryCtrl,
                        cvvCtrl: _cvvCtrl,
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          CheckoutBottomBar(
            label: orderCtrl.isPlacing ? 'Placing Order…' : 'Place Order',
            onPressed: orderCtrl.isPlacing ? null : _placeOrder,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Payment Option Row
// ──────────────────────────────────────────────
class _PaymentOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final IconData icon;
  final String label;
  final String subtitle;
  final ValueChanged<String?> onChanged;

  const _PaymentOption({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.06)
              : Colors.white,
          border: Border.all(
            color: selected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: RadioListTile<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
          title: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondaryColor),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimaryColor,
                  )),
            ],
          ),
          subtitle: Text(subtitle),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Saved Card Option
// ──────────────────────────────────────────────
class _SavedCardOption extends StatelessWidget {
  final SavedCard card;
  final bool selected;
  final VoidCallback onTap;

  const _SavedCardOption({
    required this.card,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.06)
              : Colors.white,
          border: Border.all(
            color: selected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: RadioListTile<String>(
          value: card.cardId,
          groupValue: selected ? card.cardId : null,
          onChanged: (_) => onTap(),
          activeColor: AppTheme.primaryColor,
          title: Text(
            card.maskedCardNumber,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${card.cardholderName} • Expires ${card.expiryDate}'
            '${card.isDefault ? ' • Default' : ''}',
          ),
          secondary: const Icon(Icons.credit_card),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Section Card
// ──────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Card Form (fields shared with the Saved Cards screen — see
// lib/Utils/card_form_fields.dart)
// ──────────────────────────────────────────────
class _CardForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController cardNumberCtrl;
  final TextEditingController cardNameCtrl;
  final TextEditingController expiryCtrl;
  final TextEditingController cvvCtrl;

  const _CardForm({
    required this.formKey,
    required this.cardNumberCtrl,
    required this.cardNameCtrl,
    required this.expiryCtrl,
    required this.cvvCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: CardDetailsFormFields(
            cardNumberCtrl: cardNumberCtrl,
            cardNameCtrl: cardNameCtrl,
            expiryCtrl: expiryCtrl,
            cvvCtrl: cvvCtrl,
          ),
        ),
      ),
    );
  }
}
