import 'package:cloud_firestore/cloud_firestore.dart';

class DroneRentalModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String description;
  final double pricePerDay;
  final List<String> imageUrls;
  final Map<String, dynamic> specs;
  final bool isAvailable;
  final List<DateTime>? bookedDates;

  DroneRentalModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.description,
    required this.pricePerDay,
    required this.imageUrls,
    required this.specs,
    required this.isAvailable,
    this.bookedDates,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'title': title,
      'description': description,
      'pricePerDay': pricePerDay,
      'imageUrls': imageUrls,
      'specs': specs,
      'isAvailable': isAvailable,
      'bookedDates':
          bookedDates != null
              ? bookedDates!.map((date) => Timestamp.fromDate(date)).toList()
              : [],
    };
  }

  factory DroneRentalModel.fromJson(Map<String, dynamic> json) {
    List<dynamic>? bookedTimestamps = json['bookedDates'];
    List<DateTime>? bookedDates;

    if (bookedTimestamps != null) {
      bookedDates =
          bookedTimestamps
              .map((timestamp) => (timestamp as Timestamp).toDate())
              .toList();
    }

    return DroneRentalModel(
      id: json['id'],
      ownerId: json['ownerId'],
      ownerName: json['ownerName'],
      title: json['title'],
      description: json['description'],
      pricePerDay: json['pricePerDay'].toDouble(),
      imageUrls: List<String>.from(json['imageUrls']),
      specs: json['specs'] ?? {},
      isAvailable: json['isAvailable'] ?? true,
      bookedDates: bookedDates,
    );
  }
}
