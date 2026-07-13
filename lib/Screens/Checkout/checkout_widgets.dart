import 'package:flutter/material.dart';

import '../../Utils/app_theme.dart';

// ──────────────────────────────────────────────
// Step Indicator (shared across all 3 checkout screens)
// ──────────────────────────────────────────────

class CheckoutStepIndicator extends StatelessWidget {
  /// 1 = Address, 2 = Payment, 3 = Confirm
  final int current;

  const CheckoutStepIndicator({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    const steps = ['Address', 'Payment', 'Confirm'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final done = (i ~/ 2) < current - 1;
            return Expanded(
              child: Divider(
                thickness: 2,
                color: done ? AppTheme.primaryColor : Colors.grey.shade300,
              ),
            );
          }
          final idx = i ~/ 2 + 1;
          final active = idx == current;
          final done = idx < current;
          return CheckoutStepDot(
            label: steps[i ~/ 2],
            index: idx,
            active: active,
            done: done,
          );
        }),
      ),
    );
  }
}

class CheckoutStepDot extends StatelessWidget {
  final String label;
  final int index;
  final bool active;
  final bool done;

  const CheckoutStepDot({
    super.key,
    required this.label,
    required this.index,
    required this.active,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        (active || done) ? AppTheme.primaryColor : Colors.grey.shade400;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color,
          child: done
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Bottom action bar (shared across checkout screens)
// ──────────────────────────────────────────────

class CheckoutBottomBar extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const CheckoutBottomBar({
    super.key,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
