class CartItem {
  final String productId;
  final String name;
  final String brand;
  final String image;
  final double price;
  final int stock;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.brand,
    required this.image,
    required this.price,
    required this.stock,
    this.quantity = 1,
  });

  double get subtotal => price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] ?? '',
      name: json['name'] ?? 'N/A',
      brand: json['brand'] ?? '',
      image: json['image'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'brand': brand,
      'image': image,
      'price': price,
      'stock': stock,
      'quantity': quantity,
    };
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      name: name,
      brand: brand,
      image: image,
      price: price,
      stock: stock,
      quantity: quantity ?? this.quantity,
    );
  }
}
