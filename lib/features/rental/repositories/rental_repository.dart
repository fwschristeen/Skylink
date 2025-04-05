import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drone_user_app/features/rental/models/drone_rental_model.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class RentalRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Get all available drones for rent
  Future<List<DroneRentalModel>> getAvailableDrones() async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('rentals')
              .where('isAvailable', isEqualTo: true)
              .get();

      return snapshot.docs
          .map(
            (doc) =>
                DroneRentalModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting available drones: $e');
      return [];
    }
  }

  // Get drones owned by a specific user
  Future<List<DroneRentalModel>> getUserDrones(String userId) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('rentals')
              .where('ownerId', isEqualTo: userId)
              .get();

      return snapshot.docs
          .map(
            (doc) =>
                DroneRentalModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting user drones: $e');
      return [];
    }
  }

  // Add a new drone for rent
  Future<bool> addDroneForRent(DroneRentalModel drone) async {
    try {
      String id = _uuid.v4();
      DroneRentalModel droneWithId = DroneRentalModel(
        id: id,
        ownerId: drone.ownerId,
        ownerName: drone.ownerName,
        title: drone.title,
        description: drone.description,
        pricePerDay: drone.pricePerDay,
        imageUrls: drone.imageUrls,
        specs: drone.specs,
        isAvailable: true,
      );

      await _firestore.collection('rentals').doc(id).set(droneWithId.toJson());

      return true;
    } catch (e) {
      debugPrint('Error adding drone for rent: $e');
      return false;
    }
  }

  // Update an existing rental drone
  Future<bool> updateDroneRental(DroneRentalModel drone) async {
    try {
      await _firestore
          .collection('rentals')
          .doc(drone.id)
          .update(drone.toJson());

      return true;
    } catch (e) {
      debugPrint('Error updating drone rental: $e');
      return false;
    }
  }

  // Book a drone for specific dates
  Future<bool> bookDrone(
    String droneId,
    List<DateTime> dates,
    String userId,
  ) async {
    try {
      // Get the current drone data
      DocumentSnapshot doc =
          await _firestore.collection('rentals').doc(droneId).get();

      if (!doc.exists) {
        return false;
      }

      DroneRentalModel drone = DroneRentalModel.fromJson(
        doc.data() as Map<String, dynamic>,
      );

      // Check if drone is available
      if (!drone.isAvailable) {
        return false;
      }

      // Check if any of the dates are already booked
      List<DateTime> bookedDates = drone.bookedDates ?? [];
      for (DateTime date in dates) {
        if (bookedDates.any(
          (bookedDate) =>
              bookedDate.year == date.year &&
              bookedDate.month == date.month &&
              bookedDate.day == date.day,
        )) {
          return false;
        }
      }

      // Add the new dates to the booked dates
      bookedDates.addAll(dates);

      // Update the drone with new booked dates
      await _firestore.collection('rentals').doc(droneId).update({
        'bookedDates':
            bookedDates.map((date) => Timestamp.fromDate(date)).toList(),
      });

      // Create a booking record
      await _firestore.collection('bookings').add({
        'droneId': droneId,
        'userId': userId,
        'dates': dates.map((date) => Timestamp.fromDate(date)).toList(),
        'bookingDate': Timestamp.fromDate(DateTime.now()),
        'status': 'confirmed',
      });

      return true;
    } catch (e) {
      debugPrint('Error booking drone: $e');
      return false;
    }
  }

  // Delete a drone rental listing
  Future<bool> deleteDroneRental(String droneId) async {
    try {
      await _firestore.collection('rentals').doc(droneId).delete();

      return true;
    } catch (e) {
      debugPrint('Error deleting drone rental: $e');
      return false;
    }
  }
}
