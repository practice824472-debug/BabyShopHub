import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Controllers/auth_controller.dart';
import '../../Models/address_model.dart';
import '../../Utils/app_theme.dart';
import '../../Utils/pakistan_cities.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
        onPressed: () => _showAddDialog(context),
      ),
      body: Consumer<AuthController>(
        builder: (context, auth, _) {
          if (auth.addresses.isEmpty) {
            return _EmptyState(
              onAdd: () => _showAddDialog(context),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: auth.addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _AddressTile(
                address: auth.addresses[index],
                onDelete: () => _confirmDelete(context, auth, index),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final streetCtrl = TextEditingController();
    final postalCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    // Use the same fixed city list as checkout, so a saved address's city
    // always matches an item in the checkout city dropdown later.
    String? selectedCity;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Address'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: streetCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Street / Apartment',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCity,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  items: pakistanCities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedCity = v),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Please select a city' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: postalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Postal Code',
                    prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final address = AddressModel(
        street: streetCtrl.text.trim(),
        city: selectedCity ?? '',
        postalCode: postalCtrl.text.trim(),
      );
      final auth = context.read<AuthController>();
      final success = await auth.addAddress(address);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Failed to save address.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, AuthController auth, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text(
          '"${auth.addresses[index]}"',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
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
      final success = await auth.deleteAddress(index);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Failed to delete address.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

// ──────────────────────────────────────────────

class _AddressTile extends StatelessWidget {
  final AddressModel address;
  final VoidCallback onDelete;

  const _AddressTile({required this.address, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.location_on_outlined,
            color: AppTheme.primaryColor),
        title: Text(address.displayText,
            maxLines: 3, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
          onPressed: onDelete,
          tooltip: 'Delete',
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
            Icon(Icons.location_off_outlined,
                size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No saved addresses',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Add a delivery address so you can check out faster.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Address'),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}
