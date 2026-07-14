import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../Controllers/admin_controller.dart';
import '../../Models/admin_product_model.dart';
import '../../Services/cloudinary_service.dart';
import '../../Utils/product_categories.dart';
import '../../Widgets/shimmer_widgets.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AdminController>().loadProducts();
    });
  }

  /// Defers opening a dialog to the next frame instead of doing it inline
  /// inside the button's onPressed/onTap handler.
  ///
  /// On Flutter Web, opening a showDialog() synchronously from a hover-
  /// tracked Material button (FloatingActionButton, InkWell, etc.) can hit
  /// a Flutter engine re-entrancy bug in mouse_tracker.dart
  /// ("!_debugDuringDeviceUpdate is not true") because the dialog swaps out
  /// the widget the mouse is hovering over while the mouse tracker is mid
  /// update. Once that assertion fires it can leave pointer/hover event
  /// dispatch stuck, making the app look frozen until it's restarted. Firing
  /// after the current frame avoids the conflict.
  void _openDialogNextFrame(VoidCallback openDialog) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) openDialog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: Consumer<AdminController>(
        builder: (context, adminController, _) {
          if (adminController.productsLoading) {
            return const ShimmerList();
          }

          if (adminController.error != null &&
              adminController.products.isEmpty) {
            return _buildErrorState(adminController.error!, () {
              adminController.clearError();
              adminController.loadProducts();
            });
          }

          if (adminController.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Products Found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          final filteredProducts = _selectedCategory == 'All'
              ? adminController.products
              : adminController.products
                  .where((p) => p.category == _selectedCategory)
                  .toList();

          return Column(
            children: [
              _buildCategoryFilter(),
              Expanded(
                child: filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.filter_alt_off,
                                size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No products in "$_selectedCategory"',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _buildProductCard(
                              context, product, adminController);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.add),
        onPressed: () =>
            _openDialogNextFrame(() => _showAddProductDialog(context)),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: ProductCategories.withAll.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = ProductCategories.withAll[index];
          final isSelected = category == _selectedCategory;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedCategory = category),
            selectedColor: Colors.blue.shade700,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            backgroundColor: Colors.grey.shade100,
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, AdminProductModel product,
      AdminController adminController) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                  ),
                  child: product.image.isNotEmpty
                      ? Image.network(
                          product.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade400,
                            );
                          },
                        )
                      : Icon(
                          Icons.image,
                          color: Colors.grey.shade400,
                        ),
                ),
                const SizedBox(width: 12),
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.brand,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.category,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (product.isBestSeller)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Best Seller',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.w600)),
                            ),
                          if (product.isFeatured)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Featured',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.purple.shade800,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: product.stock > 0
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Stock: ${product.stock}',
                              style: TextStyle(
                                fontSize: 12,
                                color: product.stock > 0
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Edit',
                  color: Colors.blue,
                  onTap: () => _openDialogNextFrame(() =>
                      _showEditProductDialog(
                          context, product, adminController)),
                ),
                _buildActionButton(
                  icon: Icons.inventory,
                  label: 'Stock',
                  color: Colors.orange,
                  onTap: () => _openDialogNextFrame(() =>
                      _showUpdateStockDialog(
                          context, product, adminController)),
                ),
                _buildActionButton(
                  icon: Icons.delete,
                  label: 'Delete',
                  color: Colors.red,
                  onTap: () => _openDialogNextFrame(() =>
                      _showDeleteConfirmation(
                          context, product, adminController)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final brandController = TextEditingController();
    final stockController = TextEditingController();

    String selectedCategory = ProductCategories.values.first;
    Uint8List? pickedImageBytes;
    List<Uint8List> pickedGalleryBytes = [];
    bool isBestSeller = false;
    bool isFeatured = false;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add New Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImagePicker(
                  imageBytes: pickedImageBytes,
                  existingUrl: null,
                  isSaving: isSaving,
                  onPick: () async {
                    final bytes = await _pickImageBytes();
                    if (bytes != null) {
                      setDialogState(() => pickedImageBytes = bytes);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildGalleryPicker(
                  existingUrls: const [],
                  newImages: pickedGalleryBytes,
                  isSaving: isSaving,
                  onAdd: () async {
                    final bytes = await _pickImageBytes();
                    if (bytes != null) {
                      setDialogState(() =>
                          pickedGalleryBytes = [...pickedGalleryBytes, bytes]);
                    }
                  },
                  onRemoveNew: (index) {
                    setDialogState(() {
                      pickedGalleryBytes = List.of(pickedGalleryBytes)
                        ..removeAt(index);
                    });
                  },
                  onRemoveExisting: (_) {},
                ),
                const SizedBox(height: 12),
                _buildTextField(nameController, 'Product Name'),
                const SizedBox(height: 12),
                _buildTextField(descriptionController, 'Description',
                    maxLines: 2),
                const SizedBox(height: 12),
                _buildTextField(priceController, 'Price',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _buildTextField(brandController, 'Brand'),
                const SizedBox(height: 12),
                _buildCategoryDropdown(
                  value: selectedCategory,
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(stockController, 'Stock',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Best Seller'),
                  value: isBestSeller,
                  onChanged: (v) => setDialogState(() => isBestSeller = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Featured'),
                  value: isFeatured,
                  onChanged: (v) => setDialogState(() => isFeatured = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty ||
                          priceController.text.trim().isEmpty ||
                          stockController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Please fill in all required fields')),
                        );
                        return;
                      }
                      if (pickedImageBytes == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please choose a product image')),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      try {
                        final imageUrl = await CloudinaryService.uploadImage(
                          pickedImageBytes!,
                        );
                        final galleryUrls = <String>[];
                        for (final bytes in pickedGalleryBytes) {
                          galleryUrls
                              .add(await CloudinaryService.uploadImage(bytes));
                        }

                        final product = AdminProductModel(
                          productId: '',
                          name: nameController.text.trim(),
                          description: descriptionController.text.trim(),
                          price: double.parse(priceController.text),
                          brand: brandController.text.trim(),
                          category: selectedCategory,
                          image: imageUrl,
                          stock: int.parse(stockController.text),
                          rating: 0,
                          isActive: true,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                          totalReviews: 0,
                          avgRating: 0,
                          images: galleryUrls,
                          isBestSeller: isBestSeller,
                          isFeatured: isFeatured,
                        );
                        await context
                            .read<AdminController>()
                            .addProduct(product);
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Product added successfully')),
                        );
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to add product: $e')),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, AdminProductModel product,
      AdminController adminController) {
    final nameController = TextEditingController(text: product.name);
    final descriptionController =
        TextEditingController(text: product.description);
    final priceController =
        TextEditingController(text: product.price.toString());
    final brandController = TextEditingController(text: product.brand);

    String selectedCategory = ProductCategories.normalize(product.category);
    Uint8List? pickedImageBytes;
    List<Uint8List> pickedGalleryBytes = [];
    List<String> existingGalleryUrls = List.of(product.images);
    bool isBestSeller = product.isBestSeller;
    bool isFeatured = product.isFeatured;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImagePicker(
                  imageBytes: pickedImageBytes,
                  existingUrl: product.image,
                  isSaving: isSaving,
                  onPick: () async {
                    final bytes = await _pickImageBytes();
                    if (bytes != null) {
                      setDialogState(() => pickedImageBytes = bytes);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildGalleryPicker(
                  existingUrls: existingGalleryUrls,
                  newImages: pickedGalleryBytes,
                  isSaving: isSaving,
                  onAdd: () async {
                    final bytes = await _pickImageBytes();
                    if (bytes != null) {
                      setDialogState(() =>
                          pickedGalleryBytes = [...pickedGalleryBytes, bytes]);
                    }
                  },
                  onRemoveNew: (index) {
                    setDialogState(() {
                      pickedGalleryBytes = List.of(pickedGalleryBytes)
                        ..removeAt(index);
                    });
                  },
                  onRemoveExisting: (index) {
                    setDialogState(() {
                      existingGalleryUrls = List.of(existingGalleryUrls)
                        ..removeAt(index);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(nameController, 'Product Name'),
                const SizedBox(height: 12),
                _buildTextField(descriptionController, 'Description',
                    maxLines: 2),
                const SizedBox(height: 12),
                _buildTextField(priceController, 'Price',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _buildTextField(brandController, 'Brand'),
                const SizedBox(height: 12),
                _buildCategoryDropdown(
                  value: selectedCategory,
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Best Seller'),
                  value: isBestSeller,
                  onChanged: (v) => setDialogState(() => isBestSeller = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Featured'),
                  value: isFeatured,
                  onChanged: (v) => setDialogState(() => isFeatured = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        String imageUrl = product.image;
                        if (pickedImageBytes != null) {
                          imageUrl = await CloudinaryService.uploadImage(
                            pickedImageBytes!,
                          );
                        }
                        final newGalleryUrls = <String>[];
                        for (final bytes in pickedGalleryBytes) {
                          newGalleryUrls
                              .add(await CloudinaryService.uploadImage(bytes));
                        }
                        final combinedGallery = [
                          ...existingGalleryUrls,
                          ...newGalleryUrls
                        ];

                        final updatedProduct = AdminProductModel(
                          productId: product.productId,
                          name: nameController.text.trim(),
                          description: descriptionController.text.trim(),
                          price: double.parse(priceController.text),
                          brand: brandController.text.trim(),
                          category: selectedCategory,
                          image: imageUrl,
                          stock: product.stock,
                          rating: product.rating,
                          isActive: product.isActive,
                          createdAt: product.createdAt,
                          updatedAt: DateTime.now(),
                          totalReviews: product.totalReviews,
                          avgRating: product.avgRating,
                          images: combinedGallery,
                          isBestSeller: isBestSeller,
                          isFeatured: isFeatured,
                        );
                        await adminController.updateProduct(
                            product.productId, updatedProduct);
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Product updated successfully')),
                        );
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Failed to update product: $e')),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateStockDialog(BuildContext context, AdminProductModel product,
      AdminController adminController) {
    final stockController =
        TextEditingController(text: product.stock.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Stock'),
        content: _buildTextField(stockController, 'New Stock',
            keyboardType: TextInputType.number),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              adminController.updateProductStock(
                product.productId,
                int.parse(stockController.text),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stock updated successfully')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AdminProductModel product,
      AdminController adminController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              adminController.deleteProduct(product.productId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product deleted successfully')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Picks an image from the gallery and returns its raw bytes (works on
  /// every platform, including web where the path is a blob URL).
  Future<Uint8List?> _pickImageBytes() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return picked.readAsBytes();
  }

  Widget _buildImagePicker({
    required Uint8List? imageBytes,
    required String? existingUrl,
    required bool isSaving,
    required VoidCallback onPick,
  }) {
    final hasNewImage = imageBytes != null;
    final hasExistingImage =
        !hasNewImage && existingUrl != null && existingUrl.isNotEmpty;

    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade200,
          ),
          clipBehavior: Clip.antiAlias,
          child: hasNewImage
              ? Image.memory(imageBytes, fit: BoxFit.cover)
              : hasExistingImage
                  ? Image.network(
                      existingUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade400,
                      ),
                    )
                  : Icon(Icons.image, size: 40, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: isSaving ? null : onPick,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(hasNewImage || hasExistingImage
              ? 'Change Photo'
              : 'Choose Photo'),
        ),
      ],
    );
  }

  /// Multi-image gallery picker used alongside the primary image picker.
  /// Shows existing (already-uploaded) gallery URLs plus newly picked
  /// images, each removable, with an "Add" tile to pick more.
  Widget _buildGalleryPicker({
    required List<String> existingUrls,
    required List<Uint8List> newImages,
    required bool isSaving,
    required VoidCallback onAdd,
    required ValueChanged<int> onRemoveNew,
    required ValueChanged<int> onRemoveExisting,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gallery Images (optional)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          SizedBox(
            height: 76,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (int i = 0; i < existingUrls.length; i++)
                  _galleryThumb(
                    child: Image.network(existingUrls[i], fit: BoxFit.cover),
                    onRemove: isSaving ? null : () => onRemoveExisting(i),
                  ),
                for (int i = 0; i < newImages.length; i++)
                  _galleryThumb(
                    child: Image.memory(newImages[i], fit: BoxFit.cover),
                    onRemove: isSaving ? null : () => onRemoveNew(i),
                  ),
                GestureDetector(
                  onTap: isSaving ? null : onAdd,
                  child: Container(
                    width: 68,
                    height: 68,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Icon(Icons.add_photo_alternate_outlined,
                        color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _galleryThumb({required Widget child, VoidCallback? onRemove}) {
    return Container(
      width: 68,
      height: 68,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(width: 68, height: 68, child: child),
          ),
          if (onRemove != null)
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: onRemove,
                child: const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: ProductCategories.values
          .map(
            (category) => DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Unable to load data',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
