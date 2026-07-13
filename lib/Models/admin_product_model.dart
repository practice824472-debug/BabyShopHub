import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProductModel {
  final String productId;
  final String name;
  final String description;
  final double price;
  final String brand;
  final String category;
  final String image;
  final int stock;
  final double rating;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalReviews;
  final double avgRating;
  final List<String> images;
  final bool isBestSeller;
  final bool isFeatured;

  AdminProductModel({
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.brand,
    required this.category,
    required this.image,
    required this.stock,
    required this.rating,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.totalReviews,
    required this.avgRating,
    this.images = const [],
    this.isBestSeller = false,
    this.isFeatured = false,
  });

  factory AdminProductModel.fromJson(Map<String, dynamic> json, String productId) {
    return AdminProductModel(
      productId: productId,
      name: json['name'] ?? 'N/A',
      description: json['description'] ?? '',
      price: _toDouble(json['price']),
      brand: json['brand'] ?? 'N/A',
      category: json['category'] ?? 'N/A',
      image: json['image'] ?? '',
      stock: _toInt(json['stock']),
      rating: _toDouble(json['rating']),
      isActive: json['isActive'] ?? true,
      createdAt: _toDateTime(json['createdAt']),
      updatedAt: _toDateTime(json['updatedAt']),
      totalReviews: _toInt(json['totalReviews']),
      avgRating: _toDouble(json['avgRating']),
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      isBestSeller: json['isBestSeller'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'brand': brand,
      'category': category,
      'image': image,
      'stock': stock,
      'rating': rating,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'totalReviews': totalReviews,
      'avgRating': avgRating,
      'images': images,
      'isBestSeller': isBestSeller,
      'isFeatured': isFeatured,
    };
  }
}
