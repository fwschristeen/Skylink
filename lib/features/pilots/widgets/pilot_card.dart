import 'package:drone_user_app/features/pilots/models/pilot_model.dart';
import 'package:flutter/material.dart';

class PilotCard extends StatelessWidget {
  final PilotModel pilot;
  final VoidCallback onTap;

  const PilotCard({super.key, required this.pilot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildPilotImage(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pilot.name ?? 'Unnamed Pilot',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildRatingRow(),
                    const SizedBox(height: 4),
                    if (pilot.location != null && pilot.location!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              pilot.location!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    if (pilot.hourlyRate != null)
                      Text(
                        'Hourly Rate: LKR ${pilot.hourlyRate!.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 8),
                    _buildSkillsRow(),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('View Profile'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPilotImage() {
    return CircleAvatar(
      radius: 40,
      backgroundImage:
          pilot.imageUrl != null && pilot.imageUrl!.isNotEmpty
              ? NetworkImage(pilot.imageUrl!)
              : null,
      child:
          pilot.imageUrl == null || pilot.imageUrl!.isEmpty
              ? const Icon(Icons.person, size: 40)
              : null,
    );
  }

  Widget _buildRatingRow() {
    final hasRating = pilot.rating != null;
    return Row(
      children: [
        Icon(
          Icons.star,
          size: 16,
          color: hasRating ? Colors.amber : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          hasRating
              ? '${pilot.rating!.toStringAsFixed(1)} (${pilot.reviewCount ?? 0})'
              : 'No ratings yet',
        ),
      ],
    );
  }

  Widget _buildSkillsRow() {
    if (pilot.skills == null || pilot.skills!.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 30,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pilot.skills!.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Text(
              pilot.skills![index],
              style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
            ),
          );
        },
      ),
    );
  }
}
