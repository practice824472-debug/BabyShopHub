class SavedCard {
  final String cardId;
  final String cardNumber; // Last 4 digits only stored
  final String cardholderName;
  final String expiryDate; // MM/YY
  final String cvv; // Only for display after verification
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SavedCard({
    required this.cardId,
    required this.cardNumber,
    required this.cardholderName,
    required this.expiryDate,
    required this.cvv,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
  });

  // Get masked card number (e.g., "**** **** **** 1234")
  String get maskedCardNumber => '•••• •••• •••• ${cardNumber.substring(cardNumber.length - 4)}';

  Map<String, dynamic> toJson() => {
    'cardId': cardId,
    'cardNumber': cardNumber,
    'cardholderName': cardholderName,
    'expiryDate': expiryDate,
    'isDefault': isDefault,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory SavedCard.fromJson(Map<String, dynamic> json) => SavedCard(
    cardId: json['cardId'] ?? '',
    cardNumber: json['cardNumber'] ?? '',
    cardholderName: json['cardholderName'] ?? '',
    expiryDate: json['expiryDate'] ?? '',
    cvv: json['cvv'] ?? '',
    isDefault: json['isDefault'] ?? false,
    createdAt: json['createdAt'] is String
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
    updatedAt: json['updatedAt'] is String
        ? DateTime.parse(json['updatedAt'])
        : null,
  );

  SavedCard copyWith({
    String? cardId,
    String? cardNumber,
    String? cardholderName,
    String? expiryDate,
    String? cvv,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SavedCard(
    cardId: cardId ?? this.cardId,
    cardNumber: cardNumber ?? this.cardNumber,
    cardholderName: cardholderName ?? this.cardholderName,
    expiryDate: expiryDate ?? this.expiryDate,
    cvv: cvv ?? this.cvv,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}