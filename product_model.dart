import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum ProductType { drone, image, video }

class ProductModel {
  final String? id;
  final String? title;
  final String? description;
  final double? price;
  final List<String>? imageUrls;
  final String? videoUrl;
  final ProductType type;
  final String? sellerId;
  final String? sellerName;
  final DateTime? createdAt;
  final Map<String, dynamic>? specifications;

  ProductModel({
    this.id,
    this.title,
    this.description,
    this.price,
    this.imageUrls,
    this.videoUrl,
    required this.type,
    this.sellerId,
    this.sellerName,
    this.createdAt,
    this.specifications,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'type': type.toString(),
      'sellerId': sellerId,
      'sellerName': sellerName,
      'createdAt': createdAt,
      'specifications': specifications,
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: json['price']?.toDouble(),
      imageUrls:
          json['imageUrls'] != null
              ? List<String>.from(json['imageUrls'])
              : null,
      videoUrl: json['videoUrl'],
      type: ProductType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ProductType.drone,
      ),
      sellerId: json['sellerId'],
      sellerName: json['sellerName'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      specifications: json['specs'],
    );
  }

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return ProductModel(type: ProductType.drone);

    // Debug the type field
    final typeStr = data['type'];
    debugPrint('Product ${doc.id} - Type from Firestore: $typeStr');

    ProductType productType = ProductType.drone; // Default
    try {
      if (typeStr != null) {
        // Try to handle different formats of the type field
        if (typeStr == 'ProductType.drone') {
          productType = ProductType.drone;
        } else if (typeStr == 'ProductType.image') {
          productType = ProductType.image;
        } else if (typeStr == 'ProductType.video') {
          productType = ProductType.video;
        } else if (typeStr == 'drone') {
          productType = ProductType.drone;
        } else if (typeStr == 'image') {
          productType = ProductType.image;
        } else if (typeStr == 'video') {
          productType = ProductType.video;
        } else {
          // Full enum toString() value: Try to parse from "ProductType.value"
          productType = ProductType.values.firstWhere(
            (e) => e.toString() == typeStr,
            orElse: () => ProductType.drone,
          );
        }
      }
    } catch (e) {
      debugPrint('Error parsing product type: $e');
    }

    debugPrint('Product ${doc.id} - Type after parsing: $productType');
    debugPrint('Product ${doc.id} - SellerId: ${data['sellerId']}');

    return ProductModel(
      id: doc.id,
      title: data['title'],
      description: data['description'],
      price: data['price']?.toDouble(),
      imageUrls:
          data['imageUrls'] != null
              ? List<String>.from(data['imageUrls'])
              : null,
      videoUrl: data['videoUrl'],
      type: productType,
      sellerId: data['sellerId'],
      sellerName: data['sellerName'],
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
      specifications: data['specs'] ?? data['specifications'],
    );
  }
}
