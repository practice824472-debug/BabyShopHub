import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../../Controllers/review_controller.dart';
import '../../Models/product_model.dart';
import '../../Models/review_model.dart';

class ReviewsScreen extends StatefulWidget {
  final ProductModel product;

  const ReviewsScreen({super.key, required this.product});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
          () => context.read<ReviewController>().fetchProductReviews(widget.product.productId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reviews & Ratings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Reviews'),
              Tab(text: 'Write Review'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ReviewsList(product: widget.product),
            _WriteReviewTab(product: widget.product),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Reviews List Tab
// ──────────────────────────────────────────────
class _ReviewsList extends StatelessWidget {
  final ProductModel product;

  const _ReviewsList({required this.product});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewController>(
      builder: (context, reviewCtrl, _) {
        if (reviewCtrl.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (reviewCtrl.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text('Error loading reviews'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => reviewCtrl.fetchProductReviews(product.productId),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        if (reviewCtrl.reviews.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rate_review_outlined, size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'No reviews yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Be the first to review this product',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            // Rating summary header
            SliverToBoxAdapter(
              child: _RatingSummary(product: product, reviews: reviewCtrl.reviews),
            ),
            const SliverToBoxAdapter(child: Divider()),

            // Reviews list
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _ReviewCard(
                  review: reviewCtrl.reviews[index],
                  onHelpful: () => reviewCtrl.markAsHelpful(reviewCtrl.reviews[index].reviewId),
                ),
                childCount: reviewCtrl.reviews.length,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// Rating Summary Widget
// ──────────────────────────────────────────────
class _RatingSummary extends StatelessWidget {
  final ProductModel product;
  final List<ReviewModel> reviews;

  const _RatingSummary({
    required this.product,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var review in reviews) {
      distribution[review.rating.toInt()] = (distribution[review.rating.toInt()] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.avgRating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      RatingBar.builder(
                        initialRating: product.avgRating,
                        minRating: 0,
                        allowHalfRating: true,
                        itemSize: 18,
                        ignoreGestures: true,
                        itemBuilder: (_, __) =>
                        const Icon(Icons.star, color: Colors.amber),
                        onRatingUpdate: (_) {},
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${reviews.length} reviews',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int star = 5; star >= 1; star--)
                    _RatingBar(
                      stars: star,
                      count: distribution[star] ?? 0,
                      total: reviews.length,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Rating Bar (Summary)
// ──────────────────────────────────────────────
class _RatingBar extends StatelessWidget {
  final int stars;
  final int count;
  final int total;

  const _RatingBar({
    required this.stars,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0 : (count / total * 100).toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$stars★',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : count / total,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(
                  stars >= 4
                      ? Colors.green
                      : stars == 3
                      ? Colors.orange
                      : Colors.red,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '$percentage%',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Review Card
// ──────────────────────────────────────────────
class _ReviewCard extends StatefulWidget {
  final ReviewModel review;
  final VoidCallback onHelpful;

  const _ReviewCard({
    required this.review,
    required this.onHelpful,
  });

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _isHelpfulMarked = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user and rating
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.review.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      RatingBar.builder(
                        initialRating: widget.review.rating,
                        minRating: 0,
                        itemSize: 16,
                        ignoreGestures: true,
                        itemBuilder: (_, __) =>
                        const Icon(Icons.star, color: Colors.amber),
                        onRatingUpdate: (_) {},
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(widget.review.createdAt),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Review comment
            Text(
              widget.review.comment,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),

            // Helpful button
            Row(
              children: [
                TextButton.icon(
                  onPressed: _isHelpfulMarked
                      ? null
                      : () {
                    setState(() => _isHelpfulMarked = true);
                    widget.onHelpful();
                  },
                  icon: Icon(
                    _isHelpfulMarked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 16,
                  ),
                  label: Text(
                    'Helpful (${widget.review.helpful})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
    return '${(diff.inDays / 365).floor()} years ago';
  }
}

// ──────────────────────────────────────────────
// Write Review Tab
// ──────────────────────────────────────────────
class _WriteReviewTab extends StatefulWidget {
  final ProductModel product;

  const _WriteReviewTab({required this.product});

  @override
  State<_WriteReviewTab> createState() => _WriteReviewTabState();
}

class _WriteReviewTabState extends State<_WriteReviewTab> {
  double _selectedRating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a review')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final reviewCtrl = context.read<ReviewController>();
    final success = await reviewCtrl.addReview(
      productId: widget.product.productId,
      rating: _selectedRating,
      comment: _commentController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );
      _commentController.clear();
      setState(() => _selectedRating = 5);

      // Refresh reviews list
      await reviewCtrl.fetchProductReviews(widget.product.productId);

      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reviewCtrl.error ?? 'Failed to submit review')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: widget.product.image.isNotEmpty
                      ? Image.network(
                    widget.product.image,
                    fit: BoxFit.cover,
                  )
                      : Icon(Icons.image, color: Colors.grey.shade400),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.product.brand,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Rating selector
          Text(
            'Rate this product',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Center(
            child: RatingBar.builder(
              initialRating: _selectedRating,
              minRating: 1,
              allowHalfRating: false,
              itemSize: 40,
              itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                setState(() => _selectedRating = rating);
              },
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _getRatingLabel(_selectedRating.toInt()),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Comment input
          Text(
            'Write your review',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 5,
            minLines: 4,
            decoration: InputDecoration(
              hintText: 'Share your experience with this product...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitReview,
              icon: _isSubmitting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.send),
              label: Text(_isSubmitting ? 'Submitting...' : 'Submit Review'),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 5:
        return 'Excellent! ⭐⭐⭐⭐⭐';
      case 4:
        return 'Good ⭐⭐⭐⭐';
      case 3:
        return 'Average ⭐⭐⭐';
      case 2:
        return 'Poor ⭐⭐';
      case 1:
        return 'Terrible ⭐';
      default:
        return '';
    }
  }
}
