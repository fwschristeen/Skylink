import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drone_user_app/features/pilots/models/pilot_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class PilotRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // Get all pilots
  Future<List<PilotModel>> getAllPilots() async {
    try {
      final snapshot = await _firestore.collection('pilots').get();
      return snapshot.docs.map((doc) => PilotModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting all pilots: $e');
      throw Exception('Failed to load pilots: $e');
    }
  }

  // Get pilot by ID
  Future<PilotModel?> getPilotById(String pilotId) async {
    try {
      final doc = await _firestore.collection('pilots').doc(pilotId).get();
      if (!doc.exists) {
        return null;
      }
      return PilotModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting pilot by ID: $e');
      throw Exception('Failed to load pilot: $e');
    }
  }

  // Add a new pilot
  Future<bool> addPilot(PilotModel pilot) async {
    try {
      final pilotId = pilot.id ?? _uuid.v4();
      await _firestore
          .collection('pilots')
          .doc(pilotId)
          .set(
            PilotModel(
              id: pilotId,
              name: pilot.name,
              email: pilot.email,
              phoneNumber: pilot.phoneNumber,
              imageUrl: pilot.imageUrl,
              description: pilot.description,
              skills: pilot.skills,
              hourlyRate: pilot.hourlyRate,
              isAvailable: pilot.isAvailable,
              rating: pilot.rating,
              reviewCount: pilot.reviewCount,
              certificateUrls: pilot.certificateUrls,
              location: pilot.location,
              experience: pilot.experience,
              caAslLicenceNo: pilot.caAslLicenceNo,
            ).toJson(),
          );
      return true;
    } catch (e) {
      debugPrint('Error adding pilot: $e');
      throw Exception('Failed to add pilot: $e');
    }
  }

  // Update an existing pilot
  Future<bool> updatePilot(PilotModel pilot) async {
    try {
      if (pilot.id == null) {
        throw Exception('Cannot update a pilot without an ID');
      }
      await _firestore
          .collection('pilots')
          .doc(pilot.id)
          .update(pilot.toJson());
      return true;
    } catch (e) {
      debugPrint('Error updating pilot: $e');
      throw Exception('Failed to update pilot: $e');
    }
  }

  // Delete a pilot and associated media
  Future<bool> deletePilot(String pilotId) async {
    try {
      // Get pilot data first to retrieve image URLs
      final pilotDoc = await _firestore.collection('pilots').doc(pilotId).get();
      if (pilotDoc.exists) {
        final pilot = PilotModel.fromFirestore(pilotDoc);

        // Delete profile image if exists
        if (pilot.imageUrl != null && pilot.imageUrl!.isNotEmpty) {
          try {
            final ref = _storage.refFromURL(pilot.imageUrl!);
            await ref.delete();
          } catch (e) {
            debugPrint('Error deleting profile image: $e');
          }
        }

        // Delete certificate images if exist
        if (pilot.certificateUrls != null &&
            pilot.certificateUrls!.isNotEmpty) {
          for (final certUrl in pilot.certificateUrls!) {
            try {
              final ref = _storage.refFromURL(certUrl);
              await ref.delete();
            } catch (e) {
              debugPrint('Error deleting certificate: $e');
            }
          }
        }
      }

      // Finally delete the document
      await _firestore.collection('pilots').doc(pilotId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting pilot: $e');
      throw Exception('Failed to delete pilot: $e');
    }
  }

  // Check if a user has a pilot profile
  Future<bool> hasPilotProfile(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('pilots')
              .where('id', isEqualTo: userId)
              .limit(1)
              .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking pilot profile: $e');
      return false;
    }
  }

  // Upload a certificate image and get URL
  Future<String?> uploadCertificateImage(
    String userId,
    dynamic imageFile,
  ) async {
    try {
      final ref = _storage.ref().child(
        'certificates/$userId/${_uuid.v4()}.jpg',
      );

      final uploadTask = await ref.putFile(imageFile);
      if (uploadTask.state == TaskState.success) {
        final url = await ref.getDownloadURL();
        return url;
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading certificate image: $e');
      return null;
    }
  }
}
