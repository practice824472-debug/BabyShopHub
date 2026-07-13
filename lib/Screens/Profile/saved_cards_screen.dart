import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Controllers/payment_controller.dart';
import '../../Models/card_model.dart';
import '../../Utils/app_theme.dart';
import '../../Utils/card_form_fields.dart';

class SavedCardsScreen extends StatefulWidget {
  const SavedCardsScreen({super.key});

  @override
  State<SavedCardsScreen> createState() => _SavedCardsScreenState();
}

class _SavedCardsScreenState extends State<SavedCardsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PaymentController>().fetchSavedCards());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Cards')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Card'),
        onPressed: () => _showAddDialog(context),
      ),
      body: Consumer<PaymentController>(
        builder: (context, paymentCtrl, _) {
          if (paymentCtrl.isLoading && paymentCtrl.savedCards.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (paymentCtrl.savedCards.isEmpty) {
            return _EmptyState(onAdd: () => _showAddDialog(context));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: paymentCtrl.savedCards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final card = paymentCtrl.savedCards[index];
              return _CardTile(
                card: card,
                onSetDefault: card.isDefault
                    ? null
                    : () => paymentCtrl.setDefaultCard(card.cardId),
                onDelete: () => _confirmDelete(context, paymentCtrl, card),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final cardNumberCtrl = TextEditingController();
    final cardNameCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final paymentCtrl = context.read<PaymentController>();

    bool submitting = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Card'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              // Same fields, formatting and validation as the checkout
              // payment screen's card form (lib/Utils/card_form_fields.dart)
              // so a card entered here is always accepted at checkout too.
              child: CardDetailsFormFields(
                cardNumberCtrl: cardNumberCtrl,
                cardNameCtrl: cardNameCtrl,
                expiryCtrl: expiryCtrl,
                cvvCtrl: cvvCtrl,
                autofocusCardNumber: true,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() => submitting = true);
                      final success = await paymentCtrl.saveCard(
                        cardNumber: cardNumberCtrl.text,
                        cardholderName: cardNameCtrl.text,
                        expiryDate: expiryCtrl.text,
                        cvv: cvvCtrl.text,
                        isDefault: paymentCtrl.savedCards.isEmpty,
                      );

                      if (!ctx.mounted) return;

                      if (success) {
                        Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Card saved successfully')),
                          );
                        }
                      } else {
                        setDialogState(() => submitting = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content:
                                Text(paymentCtrl.error ?? 'Failed to save card.'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Card'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, PaymentController paymentCtrl, SavedCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete card?'),
        content: Text('Remove ${card.maskedCardNumber} from your saved cards?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await paymentCtrl.deleteCard(card.cardId);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentCtrl.error ?? 'Failed to delete card.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

// ──────────────────────────────────────────────

class _CardTile extends StatelessWidget {
  final SavedCard card;
  final VoidCallback? onSetDefault;
  final VoidCallback onDelete;

  const _CardTile({
    required this.card,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.credit_card,
          color: card.isDefault ? AppTheme.primaryColor : Colors.grey,
        ),
        title: Text(card.maskedCardNumber),
        subtitle: Text(
          '${card.cardholderName} • Expires ${card.expiryDate}'
          '${card.isDefault ? ' • Default' : ''}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'default') onSetDefault?.call();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            if (onSetDefault != null)
              const PopupMenuItem(
                value: 'default',
                child: Text('Set as Default'),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.credit_card_off, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No saved cards', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Add a card so you can check out faster.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Card'),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}
