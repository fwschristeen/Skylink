import 'package:drone_user_app/features/rental/models/drone_rental_model.dart';
import 'package:drone_user_app/features/rental/repositories/rental_repository.dart';
import 'package:drone_user_app/features/rental/widgets/drone_rental_card.dart';
import 'package:flutter/material.dart';

class RentDroneScreen extends StatefulWidget {
  const RentDroneScreen({super.key});

  @override
  State<RentDroneScreen> createState() => _RentDroneScreenState();
}

class _RentDroneScreenState extends State<RentDroneScreen> {
  final RentalRepository _repository = RentalRepository();
  bool _isLoading = true;
  List<DroneRentalModel> _drones = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDrones();
  }

  Future<void> _loadDrones() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final drones = await _repository.getAvailableDrones();
      setState(() {
        _drones = drones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load drones: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rent a Drone')),
      body: RefreshIndicator(
        onRefresh: _loadDrones,
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : _drones.isEmpty
                ? const Center(child: Text('No drones available for rent'))
                : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _drones.length,
                  itemBuilder: (context, index) {
                    return DroneRentalCard(
                      drone: _drones[index],
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/drone-rental-details',
                          arguments: _drones[index],
                        );
                      },
                    );
                  },
                ),
      ),
    );
  }
}
