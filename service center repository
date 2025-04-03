import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drone_user_app/features/service_center/models/service_center_model.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ServiceCenterRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Get all service centers
  Future<List<ServiceCenterModel>> getAllServiceCenters() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection('service_centers').get();

      return snapshot.docs
          .map(
            (doc) =>
                ServiceCenterModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting all service centers: $e');
      return [];
    }
  }

  // Search service centers by query
  Future<List<ServiceCenterModel>> searchServiceCenters(String query) async {
    if (query.isEmpty) return getAllServiceCenters();

    try {
      // Normalize the query
      final searchQuery = query.toLowerCase().trim();

      // Get all service centers
      final allServiceCenters = await getAllServiceCenters();

      // Filter service centers client-side (Firestore doesn't support full-text search)
      return allServiceCenters.where((center) {
        // Check if any of these fields match our query
        return center.name.toLowerCase().contains(searchQuery) ||
            center.address.toLowerCase().contains(searchQuery) ||
            center.description.toLowerCase().contains(searchQuery) ||
            center.services.any(
              (service) => service.toLowerCase().contains(searchQuery),
            );
      }).toList();
    } catch (e) {
      debugPrint('Error searching service centers: $e');
      return [];
    }
  }

  // Get service centers owned by a specific user
  Future<List<ServiceCenterModel>> getUserServiceCenters(String userId) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('service_centers')
              .where('ownerId', isEqualTo: userId)
              .get();

      return snapshot.docs
          .map(
            (doc) =>
                ServiceCenterModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting user service centers: $e');
      return [];
    }
  }

  // Add a new service center
  Future<bool> addServiceCenter(ServiceCenterModel serviceCenter) async {
    try {
      String id = _uuid.v4();
      ServiceCenterModel serviceCenterWithId = ServiceCenterModel(
        id: id,
        ownerId: serviceCenter.ownerId,
        name: serviceCenter.name,
        address: serviceCenter.address,
        description: serviceCenter.description,
        phoneNumber: serviceCenter.phoneNumber,
        email: serviceCenter.email,
        imageUrls: serviceCenter.imageUrls,
        services: serviceCenter.services,
        location: serviceCenter.location,
        rating: null,
        reviewCount: 0,
      );

      await _firestore
          .collection('service_centers')
          .doc(id)
          .set(serviceCenterWithId.toJson());

      return true;
    } catch (e) {
      debugPrint('Error adding service center: $e');
      return false;
    }
  }

  // Update an existing service center
  Future<bool> updateServiceCenter(ServiceCenterModel serviceCenter) async {
    try {
      await _firestore
          .collection('service_centers')
          .doc(serviceCenter.id)
          .update(serviceCenter.toJson());

      return true;
    } catch (e) {
      debugPrint('Error updating service center: $e');
      return false;
    }
  }

  // Delete a service center
  Future<bool> deleteServiceCenter(String serviceCenterId) async {
    try {
      await _firestore
          .collection('service_centers')
          .doc(serviceCenterId)
          .delete();

      return true;
    } catch (e) {
      debugPrint('Error deleting service center: $e');
      return false;
    }
  }

  // Add a review for a service center
  Future<bool> addReview(
    String serviceCenterId,
    double rating,
    String reviewText,
    String userId,
  ) async {
    try {
      // Create the review
      await _firestore.collection('reviews').add({
        'serviceCenterId': serviceCenterId,
        'userId': userId,
        'rating': rating,
        'reviewText': reviewText,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update the service center's average rating
      DocumentSnapshot doc =
          await _firestore
              .collection('service_centers')
              .doc(serviceCenterId)
              .get();

      if (!doc.exists) {
        return false;
      }

      ServiceCenterModel serviceCenter = ServiceCenterModel.fromJson(
        doc.data() as Map<String, dynamic>,
      );

      double currentRating = serviceCenter.rating ?? 0;
      int currentReviewCount = serviceCenter.reviewCount ?? 0;

      // Calculate the new average rating
      double newRating;
      if (currentReviewCount == 0) {
        newRating = rating;
      } else {
        double totalRatingPoints = currentRating * currentReviewCount;
        newRating = (totalRatingPoints + rating) / (currentReviewCount + 1);
      }

      // Update the service center with the new rating
      await _firestore
          .collection('service_centers')
          .doc(serviceCenterId)
          .update({'rating': newRating, 'reviewCount': currentReviewCount + 1});

      return true;
    } catch (e) {
      debugPrint('Error adding review: $e');
      return false;
    }
  }
}
