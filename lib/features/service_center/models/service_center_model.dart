import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceCenterModel {
  final String id;
  final String ownerId;
  final String name;
  final String address;
  final String description;
  final String phoneNumber;
  final String email;
  final List<String> imageUrls;
  final List<String> services;
  final GeoPoint? location;
  final double? rating;
  final int? reviewCount;

  ServiceCenterModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.description,
    required this.phoneNumber,
    required this.email,
    required this.imageUrls,
    required this.services,
    this.location,
    this.rating,
    this.reviewCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'address': address,
      'description': description,
      'phoneNumber': phoneNumber,
      'email': email,
      'imageUrls': imageUrls,
      'services': services,
      'location': location,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  factory ServiceCenterModel.fromJson(Map<String, dynamic> json) {
    return ServiceCenterModel(
      id: json['id'],
      ownerId: json['ownerId'],
      name: json['name'],
      address: json['address'],
      description: json['description'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      imageUrls: List<String>.from(json['imageUrls']),
      services: List<String>.from(json['services']),
      location: json['location'],
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount'],
    );
  }
}
