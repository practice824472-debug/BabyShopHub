import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../Controllers/product_controller.dart';
import '../../Controllers/wishlist_controller.dart';
import '../../Widgets/product_card.dart';
import '../../Widgets/shimmer_widgets.dart';

/// Shows the current user's wishlisted products in a grid, reusing the
/// shared [ProductCard] (with its wishlist heart) so removing an item here
/// behaves identically to unhearting it anywhere else in the app.
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ProductController>().loadProducts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body: Consumer2<WishlistController, ProductController>(
        builder: (context, wishlist, productController, _) {
          if (wishlist.isLoading || productController.isLoading) {
            return const ShimmerProductGrid();
          }

          final products = productController.products
              .where((p) => wishlist.isWishlisted(p.productId))
              .toList();

          if (products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Your wishlist is empty',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap the heart on any product to save it here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              return ProductCard(product: products[index]);
            },
          );
        },
      ),
    );
  }
}
