/// A saved delivery address.
///
/// Stored in Firestore as a map (`{street, city, postalCode}`) so every
/// field can be read back directly — no re-parsing a single joined string
/// (which broke whenever a street address happened to contain a comma, or
/// silently dropped city/postal code when the format didn't line up).
class AddressModel {
  final String street;
  final String city;
  final String postalCode;

  const AddressModel({
    required this.street,
    required this.city,
    required this.postalCode,
  });

  Map<String, String> toMap() => {
        'street': street,
        'city': city,
        'postalCode': postalCode,
      };

  /// Builds an [AddressModel] from Firestore data. Accepts the new map
  /// format, and falls back to best-effort parsing of the legacy
  /// "Street, City, PostalCode" string format for addresses saved before
  /// this model existed, so old saved addresses don't just disappear.
  factory AddressModel.fromDynamic(dynamic raw) {
    if (raw is Map) {
      return AddressModel(
        street: (raw['street'] ?? '').toString(),
        city: (raw['city'] ?? '').toString(),
        postalCode: (raw['postalCode'] ?? '').toString(),
      );
    }

    final text = raw.toString();
    final parts = text.split(',').map((s) => s.trim()).toList();
    if (parts.length >= 3) {
      return AddressModel(
        street: parts[0],
        city: parts[1],
        postalCode: parts.sublist(2).join(', '),
      );
    }
    if (parts.length == 2) {
      return AddressModel(street: parts[0], city: parts[1], postalCode: '');
    }
    return AddressModel(street: text, city: '', postalCode: '');
  }

  /// Human-readable one-line summary for list tiles.
  String get displayText {
    final segments = [street, city, postalCode]
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return segments.join(', ');
  }
}
