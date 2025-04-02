import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drone_user_app/features/marketplace/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class MarketplaceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final uuid = const Uuid();

  // Get all products in the marketplace
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final querySnapshot = await _firestore.collection('products').get();
      return querySnapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting all products: $e');
      rethrow;
    }
  }

  // Search products by query
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final queryText = query.toLowerCase();

      // Get all products first (we'll filter in memory)
      final querySnapshot = await _firestore.collection('products').get();
      final allProducts =
          querySnapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList();

      // Filter products based on search query
      return allProducts.where((product) {
        final titleMatch =
            product.title?.toLowerCase().contains(queryText) ?? false;
        final descriptionMatch =
            product.description?.toLowerCase().contains(queryText) ?? false;
        final sellerNameMatch =
            product.sellerName?.toLowerCase().contains(queryText) ?? false;
        final priceMatch =
            product.price?.toString().contains(queryText) ?? false;

        return titleMatch || descriptionMatch || sellerNameMatch || priceMatch;
      }).toList();
    } catch (e) {
      debugPrint('Error searching products: $e');
      rethrow;
    }
  }

  // Get products filtered by type
  Future<List<ProductModel>> getProductsByType(ProductType type) async {
    try {
      // For reliable filtering, get all products and filter in memory
      final querySnapshot = await _firestore.collection('products').get();
      final allProducts =
          querySnapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList();

      return allProducts.where((product) => product.type == type).toList();
    } catch (e) {
      debugPrint('Error getting products by type: $e');
      rethrow;
    }
  }

  // Get products by seller ID
  Future<List<ProductModel>> getProductsBySeller(String sellerId) async {
    debugPrint('Fetching products for seller ID: $sellerId');
    try {
      // First try querying by direct field comparison
      QuerySnapshot snapshot =
          await _firestore
              .collection('products')
              .where('sellerId', isEqualTo: sellerId)
              .get();

      debugPrint(
        'Found ${snapshot.docs.length} products for seller ID: $sellerId',
      );

      // Print each product information
      if (snapshot.docs.isEmpty) {
        debugPrint('No products found in database for seller ID: $sellerId');

        // Try alternative query - let's try a broader query and filter client-side
        debugPrint('Trying broader query to identify products');
        final allSnapshot =
            await _firestore.collection('products').limit(50).get();

        debugPrint('Found ${allSnapshot.docs.length} total products');

        // Check seller IDs in all products
        for (var doc in allSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          final docSellerId = data?['sellerId'];
          debugPrint(
            'Product ${doc.id} - SellerId: $docSellerId (expected: $sellerId)',
          );
        }
      } else {
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          debugPrint(
            'Product ID: ${doc.id}, Type: ${data?['type']}, SellerId: ${data?['sellerId']}',
          );
        }
      }

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting products by seller: $e');
      return [];
    }
  }

  // Add a new product to the marketplace
  Future<bool> addProduct(ProductModel product) async {
    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .set(product.toJson());
      return true;
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // Update an existing product
  Future<bool> updateProduct(ProductModel product) async {
    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .update(product.toJson());
      return true;
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete a product and its associated media files
  Future<bool> deleteProduct(String productId) async {
    try {
      // First get the product to retrieve media URLs
      final docSnapshot =
          await _firestore.collection('products').doc(productId).get();

      if (!docSnapshot.exists) {
        debugPrint('Product not found: $productId');
        return false;
      }

      // Convert to ProductModel to get media URLs
      final product = ProductModel.fromFirestore(docSnapshot);
      final storage = FirebaseStorage.instance;

      // Delete images if present
      if (product.imageUrls != null && product.imageUrls!.isNotEmpty) {
        debugPrint(
          'Deleting ${product.imageUrls!.length} images for product: $productId',
        );

        for (final imageUrl in product.imageUrls!) {
          try {
            // Extract reference from URL
            final ref = storage.refFromURL(imageUrl);
            await ref.delete();
            debugPrint('Deleted image: ${ref.fullPath}');
          } catch (e) {
            debugPrint('Error deleting image: $e');
            // Continue deleting other images even if one fails

            // Try alternative approach if the URL format is different
            _tryDeleteFileByPath(imageUrl);
          }
        }
      }

      // Delete video if present
      if (product.videoUrl != null) {
        try {
          debugPrint('Deleting video for product: $productId');
          final ref = storage.refFromURL(product.videoUrl!);
          await ref.delete();
          debugPrint('Deleted video: ${ref.fullPath}');
        } catch (e) {
          debugPrint('Error deleting video: $e');
          // Try alternative approach if the URL format is different
          _tryDeleteFileByPath(product.videoUrl!);
        }
      }

      // Finally delete the Firestore document
      await _firestore.collection('products').doc(productId).delete();
      debugPrint('Successfully deleted product: $productId');
      return true;
    } catch (e) {
      debugPrint('Failed to delete product: $e');
      throw Exception('Failed to delete product: $e');
    }
  }

  // Try to extract and delete a file using path components
  Future<void> _tryDeleteFileByPath(String url) async {
    try {
      debugPrint('Trying alternative deletion for URL: $url');

      // Extract path components from URLs like:
      // 1. https://firebasestorage.googleapis.com/v0/b/bucket-name.appspot.com/o/path%2Fto%2Ffile.jpg?alt=media&token=...
      // 2. gs://bucket-name.appspot.com/path/to/file.jpg

      // For Firebase Storage URLs
      if (url.contains('firebasestorage.googleapis.com')) {
        final pathStart = url.indexOf('/o/') + 3;
        final pathEnd = url.indexOf('?', pathStart);

        if (pathStart >= 3 && pathEnd > pathStart) {
          final encodedPath = url.substring(pathStart, pathEnd);
          final path = Uri.decodeFull(encodedPath);

          debugPrint('Extracted path: $path');

          final storage = FirebaseStorage.instance;
          final ref = storage.ref().child(path);
          await ref.delete();
          debugPrint('Successfully deleted file at path: $path');
        }
      }
      // For gs:// URLs
      else if (url.startsWith('gs://')) {
        final pathStart = url.indexOf('/', 5);

        if (pathStart > 5) {
          final path = url.substring(pathStart + 1);

          debugPrint('Extracted path from gs URL: $path');

          final storage = FirebaseStorage.instance;
          final ref = storage.ref().child(path);
          await ref.delete();
          debugPrint('Successfully deleted file at path: $path');
        }
      }
    } catch (e) {
      debugPrint('Alternative deletion failed: $e');
    }
  }
}
