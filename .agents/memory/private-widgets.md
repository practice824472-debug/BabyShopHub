---
name: Private widgets cross-file import
description: Dart private (underscore-prefixed) classes cannot be imported across files — this is a compile blocker.
---

# Private widgets cannot be imported across files in Dart

## The rule
Any class or function prefixed with `_` is library-private in Dart. You cannot do `import 'foo.dart' show _Bar;` — this will fail compilation.

**Why:** This burned us twice in the same project (CheckoutWidgets, OrderStatusBadge). Each time a shared widget was defined as `_ClassName` and then imported by another file, causing a compile blocker.

## How to apply
- When a widget is needed by more than one screen/file, define it in its own dedicated public file (no underscore prefix) from the start.
- For checkout flow: `lib/Screens/Checkout/checkout_widgets.dart` — `CheckoutStepIndicator`, `CheckoutBottomBar`
- For orders flow: `lib/Screens/Orders/order_status_badge.dart` — `OrderStatusBadge`, `shortOrderId()`
- Always grep for `show _` patterns after creating shared-widget imports as a quick sanity check.
