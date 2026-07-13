import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../Controllers/wishlist_controller.dart';
import '../Models/product_model.dart';
import '../Utils/app_theme.dart';
import '../Screens/Products/product_details_screen.dart';

/// Public, reusable product card used on the home grid and the
/// best-sellers/featured horizontal carousels, with a wishlist heart toggle.
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final double? width;

  const ProductCard({super.key, required this.product, this.width});

  @override
  Widget build(BuildContext context) {
    final card = InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: product.image.isEmpty
                        ? Icon(Icons.image,
                            size: 48, color: Colors.grey.shade400)
                        : CachedNetworkImage(
                            imageUrl: product.image,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade400,
                            ),
                          ),
                  ),
                  if (product.isBestSeller || product.isFeatured)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _Badge(
                        label: product.isBestSeller ? 'Best Seller' : 'Featured',
                        color: product.isBestSeller
                            ? AppTheme.warningColor
                            : AppTheme.primaryColor,
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _WishlistHeart(productId: product.productId),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(product.avgRating.toStringAsFixed(1)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: card).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
    }
    return card.animate().fadeIn(duration: 300.ms);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _WishlistHeart extends StatelessWidget {
  final String productId;
  const _WishlistHeart({required this.productId});

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistController>(
      builder: (context, wishlist, _) {
        final isWishlisted = wishlist.isWishlisted(productId);
        return GestureDetector(
          onTap: () => wishlist.toggle(productId),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWishlisted ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: isWishlisted ? AppTheme.errorColor : Colors.grey.shade600,
            )
                .animate(target: isWishlisted ? 1 : 0)
                .scaleXY(begin: 1, end: 1.25, duration: 150.ms, curve: Curves.easeOut)
                .then()
                .scaleXY(begin: 1.25, end: 1, duration: 150.ms),
          ),
        );
      },
    );
  }
}
