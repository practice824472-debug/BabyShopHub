/// Canonical list of product categories shared across the app.
///
/// Both the customer-facing category filter (ProductController) and the
/// admin add/edit product dropdown read from this single source so a
/// product's category can never be mistyped or drift out of sync (e.g.
/// "Diaper" vs "Diapers" would previously break category filtering).
class ProductCategories {
  ProductCategories._();

  /// Selectable categories, excluding the "All" filter option.
  static const List<String> values = [
    'Diapers',
    'Baby Food',
    'Toys',
    'Clothes',
    'Baby Care',
    'Feeding',
    'Bath',
    'Accessories',
  ];

  /// Full list including the "All" filter option, used for browsing/filtering.
  static const List<String> withAll = ['All', ...values];

  /// Resolves a stored category string to one of [values], matching
  /// case-insensitively. Falls back to the first category if there is no
  /// match (e.g. legacy free-typed categories), so dropdowns never crash on
  /// an out-of-list value.
  static String normalize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return values.first;
    final match = values.firstWhere(
      (c) => c.toLowerCase() == raw.trim().toLowerCase(),
      orElse: () => values.first,
    );
    return match;
  }
}
