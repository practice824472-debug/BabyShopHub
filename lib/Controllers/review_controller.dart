import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Models/review_model.dart';

class ReviewController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ReviewModel> _reviews = [];
  bool _isLoading = false;
  String? _error;

  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all reviews for a specific product
  Future<void> fetchProductReviews(String productId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // NOTE: combining .where() + .orderBy() on different fields requires a
      // Firestore composite index. Sort in memory to avoid that requirement
      // (the missing index was causing "Error loading reviews").
      final snapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();

      _reviews = snapshot.docs
          .map((doc) => ReviewModel.fromJson(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _error = null;
    } catch (e) {
      _error = 'Error loading reviews: ${e.toString()}';
      _reviews = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new review
  Future<bool> addReview({
    required String productId,
    required double rating,
    required String comment,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _error = 'User not authenticated';
        return false;
      }

      // Get user data for display
      final userDoc =
      await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Anonymous';

      // Check if user already reviewed this product
      final existingReview = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: user.uid)
          .get();

      if (existingReview.docs.isNotEmpty) {
        _error = 'You have already reviewed this product';
        return false;
      }

      final review = ReviewModel(
        reviewId: '',
        productId: productId,
        userId: user.uid,
        userName: userName,
        userEmail: user.email ?? '',
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
        helpful: 0,
      );

      final docRef =
      await _firestore.collection('reviews').add(review.toJson());

      // Update product's average rating
      await _updateProductRating(productId);

      _error = null;
      return true;
    } catch (e) {
      _error = 'Error adding review: ${e.toString()}';
      return false;
    }
  }

  // Update product's average rating
  Future<void> _updateProductRating(String productId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        totalRating += (doc.data()['rating'] as num).toDouble();
      }

      final avgRating = totalRating / reviewsSnapshot.docs.length;

      await _firestore.collection('products').doc(productId).update({
        'avgRating': avgRating,
        'totalReviews': reviewsSnapshot.docs.length,
      });
    } catch (e) {
      print('Error updating product rating: $e');
    }
  }

  // Check if current user has reviewed a product
  Future<bool> hasUserReviewed(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final snapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: user.uid)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Mark review as helpful
  Future<void> markAsHelpful(String reviewId) async {
    try {
      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      if (reviewDoc.exists) {
        final currentHelpful = reviewDoc.data()?['helpful'] ?? 0;
        await _firestore
            .collection('reviews')
            .doc(reviewId)
            .update({'helpful': currentHelpful + 1});

        // Refresh reviews
        if (_reviews.isNotEmpty) {
          fetchProductReviews(_reviews.first.productId);
        }
      }
    } catch (e) {
      print('Error marking helpful: $e');
    }
  }

  // Calculate average rating
  double getAverageRating() {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<double>(0, (sum, review) => sum + review.rating);
    return sum / _reviews.length;
  }

  // Get rating distribution
  Map<int, int> getRatingDistribution() {
    final distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var review in _reviews) {
      distribution[review.rating.toInt()] =
          (distribution[review.rating.toInt()] ?? 0) + 1;
    }
    return distribution;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
