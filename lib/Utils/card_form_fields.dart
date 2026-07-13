import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Groups raw digit input into "0000 0000 0000 0000" as the user types.
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digitsOnly[i]);
    }
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

/// Formats raw digit input into "MM/YY" as the user types.
class CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digitsOnly[i]);
    }
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

/// Validates an "MM/YY" expiry string, including rejecting already-expired
/// dates. Shared so every card form (checkout + saved cards) enforces the
/// same rule.
String? validateCardExpiry(String? v) {
  if (v == null || v.length < 5) {
    return 'Invalid expiry';
  }
  try {
    final parts = v.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse('20${parts[1]}');
    final now = DateTime.now();
    final expiryDate = DateTime(year, month + 1, 0); // Last day of month
    if (expiryDate.isBefore(now)) {
      return 'Card has expired';
    }
  } catch (e) {
    return 'Invalid date format';
  }
  return null;
}

/// Card number / cardholder name / expiry / CVV fields, shared by the
/// checkout payment screen and the "Saved Cards" profile screen so both use
/// identical formatting and validation.
class CardDetailsFormFields extends StatelessWidget {
  final TextEditingController cardNumberCtrl;
  final TextEditingController cardNameCtrl;
  final TextEditingController expiryCtrl;
  final TextEditingController cvvCtrl;
  final bool autofocusCardNumber;

  const CardDetailsFormFields({
    super.key,
    required this.cardNumberCtrl,
    required this.cardNameCtrl,
    required this.expiryCtrl,
    required this.cvvCtrl,
    this.autofocusCardNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: cardNumberCtrl,
          autofocus: autofocusCardNumber,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CardNumberFormatter(),
          ],
          maxLength: 19,
          decoration: const InputDecoration(
            labelText: 'Card Number',
            prefixIcon: Icon(Icons.credit_card),
            hintText: '0000 0000 0000 0000',
            counterText: '',
          ),
          validator: (v) {
            if (v == null || v.replaceAll(' ', '').length < 16) {
              return 'Enter a valid 16-digit card number';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: cardNameCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Cardholder Name',
            prefixIcon: Icon(Icons.person_outline),
            hintText: 'AS ON CARD',
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: expiryCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CardExpiryFormatter(),
                ],
                maxLength: 5,
                decoration: const InputDecoration(
                  labelText: 'MM / YY',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  counterText: '',
                ),
                validator: validateCardExpiry,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: cvvCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 3,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  prefixIcon: Icon(Icons.security),
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.length < 3) return 'Invalid CVV';
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
