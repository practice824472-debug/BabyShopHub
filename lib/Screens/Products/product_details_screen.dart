import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../Controllers/cart_controller.dart';
import '../../Controllers/wishlist_controller.dart';
import '../../Models/product_model.dart';
import '../../Utils/app_theme.dart';
import 'reviews_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  int _galleryIndex = 0;

  @override
  void initState() {
    super.initState();
    // Pre-fill quantity from whatever is already in the cart
    final cartQty = context
        .read<CartController>()
        .quantityOf(widget.product.productId);
    if (cartQty > 0) _quantity = cartQty;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          Consumer<WishlistController>(
            builder: (context, wishlist, _) {
              final isWishlisted = wishlist.isWishlisted(product.productId);
              return IconButton(
                tooltip: isWishlisted ? 'Remove from wishlist' : 'Add to wishlist',
                onPressed: () => wishlist.toggle(product.productId),
                icon: Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  color: isWishlisted ? Colors.white : Colors.white,
                )
                    .animate(target: isWishlisted ? 1 : 0)
                    .scaleXY(begin: 1, end: 1.3, duration: 150.ms, curve: Curves.easeOut)
                    .then()
                    .scaleXY(begin: 1.3, end: 1, duration: 150.ms),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGallery(product),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      _buildStockBadge(product),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.brand,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        product.avgRating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReviewsScreen(product: product),
                          ),
                        ),
                        child: Text(
                          ' (${product.totalReviews} reviews)',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.successColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Description', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    product.description.isEmpty
                        ? 'No description available for this product.'
                        : product.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Text('Quantity', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _quantityButton(
                        icon: Icons.remove,
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          _quantity.toString(),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      _quantityButton(
                        icon: Icons.add,
                        onPressed: _quantity < product.stock
                            ? () => setState(() => _quantity++)
                            : null,
                      ),
                      const Spacer(),
                      Text('${product.stock} in stock'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer<CartController>(
            builder: (context, cart, _) {
              final alreadyInCart = cart.quantityOf(product.productId) > 0;
              return ElevatedButton.icon(
                onPressed: product.isInStock ? _addToCart : null,
                icon: Icon(alreadyInCart
                    ? Icons.shopping_cart
                    : Icons.shopping_cart_outlined),
                label: Text(alreadyInCart ? 'Update Cart' : 'Add to Cart'),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGallery(ProductModel product) {
    final images = product.galleryImages;

    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: 1.15,
        child: Container(
          width: double.infinity,
          color: Colors.grey.shade100,
          child: Icon(Icons.image, size: 90, color: Colors.grey.shade400),
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            aspectRatio: 1.15,
            viewportFraction: 1,
            enableInfiniteScroll: images.length > 1,
            onPageChanged: (index, _) => setState(() => _galleryIndex = index),
          ),
          items: images.map((url) {
            return GestureDetector(
              onTap: () => _openZoom(images, images.indexOf(url)),
              child: Container(
                width: double.infinity,
                color: Colors.grey.shade100,
                child: Hero(
                  tag: url,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, u) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, u, error) => Icon(
                      Icons.image_not_supported,
                      size: 70,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: images.asMap().entries.map((entry) {
              final isActive = entry.key == _galleryIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _openZoom(List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _GalleryZoomScreen(images: images, initialIndex: initialIndex),
      ),
    );
  }

  Future<void> _addToCart() async {
    final product = widget.product;
    final cart = context.read<CartController>();
    final wasInCart = cart.quantityOf(product.productId) > 0;

    if (wasInCart) {
      // Show confirmation sheet before updating
      _showUpdateConfirmSheet(cart, product);
      return;
    }

    await cart.setQuantity(product, _quantity);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} x$_quantity added to cart.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showUpdateConfirmSheet(CartController cart, ProductModel product) {
    final currentQty = cart.quantityOf(product.productId);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Icon(Icons.shopping_cart,
                size: 40, color: AppTheme.primaryColor),
            const SizedBox(height: 12),
            Text('Already in your cart',
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'You have $currentQty of this item in your cart.\n'
                  'Update to $_quantity?',
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await cart.setQuantity(product, _quantity);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            '${product.name} updated to x$_quantity in cart.'),
                        duration: const Duration(seconds: 2),
                      ));
                    },
                    child: const Text('Update Cart'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockBadge(ProductModel product) {
    final inStock = product.isInStock;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: inStock ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        inStock ? 'In Stock' : 'Out of Stock',
        style: TextStyle(
          color: inStock ? Colors.green.shade800 : Colors.red.shade800,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 42,
      height: 42,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
        child: Icon(icon),
      ),
    );
  }
}

/// Full-screen pinch-to-zoom gallery viewer, opened by tapping any image in
/// the product details carousel.
class _GalleryZoomScreen extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const _GalleryZoomScreen({required this.images, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Hero(
                tag: images[index],
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
