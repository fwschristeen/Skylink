import 'dart:io';
import 'package:drone_user_app/features/marketplace/models/product_model.dart';
import 'package:drone_user_app/features/marketplace/widgets/video_thumbnail_widget.dart';
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isDarkMode ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => onTap(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image or video with type indicator badge
            Stack(
              children: [
                // Product image/video
                AspectRatio(
                  aspectRatio: 1.5,
                  child:
                      product.type == ProductType.video
                          ? VideoThumbnailWidget(
                            product: product,
                            onTap: () => onTap(),
                          )
                          : (product.imageUrls != null &&
                              product.imageUrls!.isNotEmpty)
                          ? Image.network(
                            product.imageUrls!.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholder(context);
                            },
                          )
                          : _buildPlaceholder(context),
                ),

                // Product type badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? Colors.black.withOpacity(0.7)
                              : Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isDarkMode
                                ? Colors.grey.shade800
                                : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconForProductType(product.type),
                          size: 14,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getProductTypeLabel(product.type),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Price badge
                if (product.price != null)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? Colors.black.withOpacity(0.7)
                                : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'LKR ${product.price!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title ?? 'Untitled',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 14,
                        color:
                            isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.sellerName ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade200,
      child: Center(
        child: Icon(
          _getIconForProductType(product.type),
          size: 48,
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
        ),
      ),
    );
  }

  IconData _getIconForProductType(ProductType type) {
    switch (type) {
      case ProductType.drone:
        return Icons.flight;
      case ProductType.image:
        return Icons.image;
      case ProductType.video:
        return Icons.videocam;
      default:
        return Icons.shopping_bag;
    }
  }

  String _getProductTypeLabel(ProductType type) {
    switch (type) {
      case ProductType.drone:
        return 'Drone';
      case ProductType.image:
        return 'Image';
      case ProductType.video:
        return 'Video';
      default:
        return 'Product';
    }
  }
}
