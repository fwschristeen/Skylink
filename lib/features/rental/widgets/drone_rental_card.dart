import 'package:drone_user_app/features/rental/models/drone_rental_model.dart';
import 'package:flutter/material.dart';

class DroneRentalCard extends StatelessWidget {
  final DroneRentalModel drone;
  final VoidCallback onTap;

  const DroneRentalCard({super.key, required this.drone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drone image
            drone.imageUrls.isNotEmpty
                ? Image.network(
                  drone.imageUrls.first,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(
                          Icons.flight,
                          size: 48,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  },
                )
                : Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Icon(
                      Icons.flight,
                      size: 48,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            // Drone info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drone.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${drone.pricePerDay.toStringAsFixed(2)} / day',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    drone.description,
                    style: TextStyle(color: Colors.grey.shade400),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Owner: ${drone.ownerName}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
