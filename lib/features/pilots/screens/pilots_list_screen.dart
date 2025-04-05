import 'package:drone_user_app/features/pilots/models/pilot_model.dart';
import 'package:drone_user_app/features/pilots/repositories/pilot_repository.dart';
import 'package:drone_user_app/features/pilots/widgets/pilot_card.dart';
import 'package:flutter/material.dart';

class PilotsListScreen extends StatefulWidget {
  const PilotsListScreen({super.key});

  @override
  State<PilotsListScreen> createState() => _PilotsListScreenState();
}

class _PilotsListScreenState extends State<PilotsListScreen> {
  final PilotRepository _repository = PilotRepository();
  bool _isLoading = true;
  List<PilotModel> _pilots = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPilots();
  }

  Future<void> _loadPilots() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pilots = await _repository.getAllPilots();
      setState(() {
        _pilots = pilots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load pilots: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Pilots')),
      body: RefreshIndicator(
        onRefresh: _loadPilots,
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : _buildPilotsList(),
      ),
    );
  }

  Widget _buildPilotsList() {
    if (_pilots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No pilots available', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _pilots.length,
      itemBuilder: (context, index) {
        return PilotCard(
          pilot: _pilots[index],
          onTap: () {
            Navigator.pushNamed(
              context,
              '/pilot-details',
              arguments: _pilots[index],
            );
          },
        );
      },
    );
  }
}
