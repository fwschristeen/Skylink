import 'package:drone_user_app/features/pilots/models/pilot_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PilotDetailsScreen extends StatelessWidget {
  const PilotDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pilot = ModalRoute.of(context)!.settings.arguments as PilotModel;

    return Scaffold(
      appBar: AppBar(title: const Text('Pilot Profile')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, pilot),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'About',
                    pilot.description ?? 'No information provided',
                  ),
                  const SizedBox(height: 16),
                  _buildSection('Experience', '${pilot.experience ?? 0} years'),
                  const SizedBox(height: 16),
                  _buildSkillsSection(pilot),
                  const SizedBox(height: 16),
                  _buildCertificatesSection(pilot),
                  const SizedBox(height: 24),
                  _buildContactButtons(context, pilot),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PilotModel pilot) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage:
                pilot.imageUrl != null && pilot.imageUrl!.isNotEmpty
                    ? NetworkImage(pilot.imageUrl!)
                    : null,
            child:
                pilot.imageUrl == null || pilot.imageUrl!.isEmpty
                    ? const Icon(Icons.person, size: 60)
                    : null,
          ),
          const SizedBox(height: 16),
          Text(
            pilot.name ?? 'Unknown Pilot',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                '${pilot.rating?.toStringAsFixed(1) ?? 'N/A'} (${pilot.reviewCount ?? 0} reviews)',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (pilot.location != null && pilot.location!.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 4),
                Text(pilot.location!),
              ],
            ),
          const SizedBox(height: 8),
          if (pilot.caAslLicenceNo != null && pilot.caAslLicenceNo!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'CAASL License: ${pilot.caAslLicenceNo}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: pilot.isAvailable ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              pilot.isAvailable ? 'Available' : 'Not Available',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hourly Rate: LKR ${pilot.hourlyRate?.toStringAsFixed(2) ?? 'N/A'}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildSkillsSection(PilotModel pilot) {
    if (pilot.skills == null || pilot.skills!.isEmpty) {
      return _buildSection('Skills', 'No skills listed');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Skills',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              pilot.skills!.map((skill) {
                return Chip(
                  label: Text(
                    skill,
                    style: const TextStyle(color: Colors.blue),
                  ),
                  backgroundColor: Colors.transparent,
                  side: BorderSide(color: Colors.blue, width: 2),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildCertificatesSection(PilotModel pilot) {
    if (pilot.certificateUrls == null || pilot.certificateUrls!.isEmpty) {
      return _buildSection('Certificates', 'No certificates provided');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Certificates',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: pilot.certificateUrls!.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    // Show full certificate
                    showDialog(
                      context: context,
                      builder:
                          (context) => Dialog(
                            child: Image.network(
                              pilot.certificateUrls![index],
                              fit: BoxFit.contain,
                            ),
                          ),
                    );
                  },
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        pilot.certificateUrls![index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactButtons(BuildContext context, PilotModel pilot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Contact Pilot',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (pilot.phoneNumber != null && pilot.phoneNumber!.isNotEmpty)
          ElevatedButton.icon(
            onPressed: () => _makePhoneCall(pilot.phoneNumber!),
            icon: const Icon(Icons.phone),
            label: const Text('Call Pilot'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        const SizedBox(height: 8),
        if (pilot.email != null && pilot.email!.isNotEmpty)
          ElevatedButton.icon(
            onPressed: () => _sendEmail(pilot.email!),
            icon: const Icon(Icons.email),
            label: const Text('Email Pilot'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        const SizedBox(height: 12),
        const Text(
          'Contact the pilot directly to arrange your booking. Make sure to discuss your requirements, location, date, and time.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Drone Pilot Booking Inquiry',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
