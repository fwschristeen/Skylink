import 'package:cloud_firestore/cloud_firestore.dart';

class PilotModel {
  final String? id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? imageUrl;
  final String? description;
  final List<String>? skills;
  final double? hourlyRate;
  final bool isAvailable;
  final double? rating;
  final int? reviewCount;
  final List<String>? certificateUrls;
  final String? location;
  final int? experience;
  final String? caAslLicenceNo;

  PilotModel({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.imageUrl,
    this.description,
    this.skills,
    this.hourlyRate,
    this.isAvailable = true,
    this.rating,
    this.reviewCount,
    this.certificateUrls,
    this.location,
    this.experience,
    this.caAslLicenceNo,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'imageUrl': imageUrl,
      'description': description,
      'skills': skills,
      'hourlyRate': hourlyRate,
      'isAvailable': isAvailable,
      'rating': rating,
      'reviewCount': reviewCount,
      'certificateUrls': certificateUrls,
      'location': location,
      'experience': experience,
      'caAslLicenceNo': caAslLicenceNo,
    };
  }

  factory PilotModel.fromJson(Map<String, dynamic> json) {
    return PilotModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      imageUrl: json['imageUrl'],
      description: json['description'],
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      hourlyRate: json['hourlyRate']?.toDouble(),
      isAvailable: json['isAvailable'] ?? true,
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount'],
      certificateUrls:
          json['certificateUrls'] != null
              ? List<String>.from(json['certificateUrls'])
              : null,
      location: json['location'],
      experience: json['experience'],
      caAslLicenceNo: json['caAslLicenceNo'],
    );
  }

  factory PilotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return PilotModel(id: doc.id);

    return PilotModel(
      id: doc.id,
      name: data['name'],
      email: data['email'],
      phoneNumber: data['phoneNumber'],
      imageUrl: data['imageUrl'],
      description: data['description'],
      skills: data['skills'] != null ? List<String>.from(data['skills']) : null,
      hourlyRate: data['hourlyRate']?.toDouble(),
      isAvailable: data['isAvailable'] ?? true,
      rating: data['rating']?.toDouble(),
      reviewCount: data['reviewCount'],
      certificateUrls:
          data['certificateUrls'] != null
              ? List<String>.from(data['certificateUrls'])
              : null,
      location: data['location'],
      experience: data['experience'],
      caAslLicenceNo: data['caAslLicenceNo'],
    );
  }
}
