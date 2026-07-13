import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Controllers/auth_controller.dart';
import '../../Models/address_model.dart';
import '../../Models/order_model.dart';
import '../../Utils/app_theme.dart';
import '../../Utils/pakistan_cities.dart';
import 'checkout_widgets.dart';
import 'payment_screen.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();

  String? _selectedCity;

  int _selectedSavedIndex = -1;
  bool _showNewAddressForm = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final auth = context.read<AuthController>();
      await auth.fetchUserProfile();
      if (!mounted) return;
      _fullNameCtrl.text = auth.userName;
      _phoneCtrl.text = auth.userPhone;
      if (auth.addresses.isEmpty) {
        setState(() => _showNewAddressForm = true);
      }
    });
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _postalCtrl.dispose();
    super.dispose();
  }

  void _applySavedAddress(AddressModel address, int index) {
    setState(() {
      _selectedSavedIndex = index;
      _showNewAddressForm = false;
      _addressCtrl.text = address.street;
      // Only preselect the city in the dropdown if it's one of the fixed
      // options it offers — otherwise DropdownButtonFormField would be
      // asked to show a value that isn't in its `items`, and silently
      // renders as unselected.
      _selectedCity =
          pakistanCities.contains(address.city) ? address.city : null;
      _postalCtrl.text = address.postalCode;
    });
  }

  void _selectNewAddress() {
    setState(() {
      _selectedSavedIndex = -1;
      _showNewAddressForm = true;
      _addressCtrl.clear();
      _selectedCity = null;
      _postalCtrl.clear();
    });
  }

  void _continue() {
    if (_selectedSavedIndex == -1 && !_showNewAddressForm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a saved address or add a new one.'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final address = OrderAddress(
      fullName: _fullNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      addressLine: _addressCtrl.text.trim(),
      city: _selectedCity ?? '',
      postalCode: _postalCtrl.text.trim(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(address: address),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Address')),
      body: Column(
        children: [
          CheckoutStepIndicator(current: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Consumer<AuthController>(
                builder: (context, auth, _) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Where should we deliver?',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select a saved address or enter a new one.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        _SectionHeader('Recipient Info'),
                        const SizedBox(height: 12),
                        _field(
                          controller: _fullNameCtrl,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                          validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _field(
                          controller: _phoneCtrl,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Required';
                            if (v.trim().length < 7) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        if (auth.addresses.isNotEmpty) ...[
                          _SectionHeader('Saved Addresses'),
                          const SizedBox(height: 10),
                          ...auth.addresses.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final addr = entry.value;
                            final selected = _selectedSavedIndex == idx;
                            return _SavedAddressTile(
                              address: addr.displayText,
                              selected: selected,
                              onTap: () => _applySavedAddress(addr, idx),
                            );
                          }),
                          const SizedBox(height: 12),
                        ],
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _selectNewAddress,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _showNewAddressForm
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade300,
                                width: _showNewAddressForm ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_location_alt_outlined,
                                  color: _showNewAddressForm
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Use a New Address',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _showNewAddressForm
                                        ? AppTheme.primaryColor
                                        : AppTheme.textPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_showNewAddressForm ||
                            _selectedSavedIndex >= 0) ...[
                          const SizedBox(height: 20),
                          _SectionHeader(
                            _showNewAddressForm
                                ? 'New Address'
                                : 'Delivery Address',
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller: _addressCtrl,
                            label: 'Street / Apartment',
                            icon: Icons.home_outlined,
                            maxLines: 2,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          // ── CITY DROPDOWN ──
                          DropdownButtonFormField<String>(
                            value: _selectedCity,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCity = newValue;
                              });
                            },
                            items: pakistanCities.map((String city) {
                              return DropdownMenuItem<String>(
                                value: city,
                                child: Text(city),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                              labelText: 'City',
                              prefixIcon: const Icon(Icons.location_city_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a city';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _field(
                            controller: _postalCtrl,
                            label: 'Postal Code',
                            icon: Icons.markunread_mailbox_outlined,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          CheckoutBottomBar(
            label: 'Continue to Payment',
            onPressed: _continue,
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final resolvedKeyboardType = maxLines > 1
        ? TextInputType.multiline
        : (keyboardType ?? TextInputType.text);
    return TextFormField(
      controller: controller,
      keyboardType: resolvedKeyboardType,
      maxLines: maxLines,
      textInputAction:
      maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppTheme.textSecondaryColor, letterSpacing: 0.6),
    );
  }
}

class _SavedAddressTile extends StatelessWidget {
  final String address;
  final bool selected;
  final VoidCallback onTap;

  const _SavedAddressTile({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.06)
              : Colors.white,
          border: Border.all(
            color: selected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color:
              selected ? AppTheme.primaryColor : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppTheme.textPrimaryColor,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  if (selected)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}