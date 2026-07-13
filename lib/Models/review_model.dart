import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String productId;
  final String userId;
  final String userName;
  final String userEmail;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final int helpful;

  const ReviewModel({
    required this.reviewId,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.helpful,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json, String reviewId) {
    return ReviewModel(
      reviewId: reviewId,
      productId: json['productId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Anonymous',
      userEmail: json['userEmail'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      helpful: json['helpful'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'helpful': helpful,
    };
  }
}
