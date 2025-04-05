import 'package:drone_user_app/features/auth/bloc/auth_bloc.dart';
import 'package:drone_user_app/features/auth/models/user_model.dart';
import 'package:drone_user_app/features/rental/models/drone_rental_model.dart';
import 'package:drone_user_app/features/rental/repositories/rental_repository.dart';
import 'package:drone_user_app/features/rental/widgets/add_rental_drone_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class RentOutScreen extends StatefulWidget {
  const RentOutScreen({super.key});

  @override
  State<RentOutScreen> createState() => _RentOutScreenState();
}

class _RentOutScreenState extends State<RentOutScreen> {
  final RentalRepository _repository = RentalRepository();
  bool _isLoading = true;
  List<DroneRentalModel> _drones = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMyDrones();
  }

  Future<void> _loadMyDrones() async {
    final state = context.read<AuthBloc>().state;
    if (state is! Authenticated) {
      setState(() {
        _error = 'You must be logged in to view your rental drones';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final drones = await _repository.getUserDrones(state.user.uid);
      setState(() {
        _drones = drones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load your drones: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddDroneBottomSheet(UserModel user) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AddRentalDroneBottomSheet(currentUser: user),
    );

    if (result == true) {
      // Refresh drone list if a new drone was added
      _loadMyDrones();
    }
  }

  Future<void> _toggleAvailability(DroneRentalModel drone) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedDrone = DroneRentalModel(
        id: drone.id,
        ownerId: drone.ownerId,
        ownerName: drone.ownerName,
        title: drone.title,
        description: drone.description,
        pricePerDay: drone.pricePerDay,
        imageUrls: drone.imageUrls,
        specs: drone.specs,
        isAvailable: !drone.isAvailable,
        bookedDates: drone.bookedDates,
      );

      final success = await _repository.updateDroneRental(updatedDrone);
      if (success) {
        _loadMyDrones();
      } else {
        setState(() {
          _isLoading = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update drone availability'),
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      });
    }
  }

  Future<void> _deleteDrone(String droneId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Drone'),
            content: const Text(
              'Are you sure you want to delete this drone from rentals?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await _repository.deleteDroneRental(droneId);
        if (success) {
          _loadMyDrones();
        } else {
          setState(() {
            _isLoading = false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete drone')),
            );
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rent Out Drones')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : _drones.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('You have no drones listed for rent'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        final state = context.read<AuthBloc>().state;
                        if (state is Authenticated) {
                          context
                              .read<AuthBloc>()
                              .getUserData(state.user.uid)
                              .then((user) {
                                if (user != null) {
                                  _showAddDroneBottomSheet(user);
                                }
                              });
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Drone for Rent'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadMyDrones,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _drones.length,
                  itemBuilder: (context, index) {
                    final drone = _drones[index];
                    // Format the next unavailable date if any
                    String? nextBookedDate;
                    if (drone.bookedDates != null &&
                        drone.bookedDates!.isNotEmpty) {
                      final now = DateTime.now();
                      final futureBookings =
                          drone.bookedDates!
                              .where((date) => date.isAfter(now))
                              .toList();
                      if (futureBookings.isNotEmpty) {
                        futureBookings.sort();
                        nextBookedDate =
                            'Next booking: ${DateFormat('MMM dd, yyyy').format(futureBookings.first)}';
                      }
                    }

                    return Dismissible(
                      key: Key(drone.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Delete Drone'),
                                content: const Text(
                                  'Are you sure you want to delete this drone from rentals?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                        );
                      },
                      onDismissed: (direction) {
                        _deleteDrone(drone.id);
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Drone image
                            SizedBox(
                              height: 180,
                              width: double.infinity,
                              child:
                                  drone.imageUrls.isNotEmpty
                                      ? Image.network(
                                        drone.imageUrls.first,
                                        fit: BoxFit.cover,
                                      )
                                      : Container(
                                        color: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.flight,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                      ),
                            ),
                            // Drone info
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          drone.title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        'LKR ${drone.pricePerDay.toStringAsFixed(2)}/day',
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    drone.description,
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (nextBookedDate != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      nextBookedDate,
                                      style: TextStyle(
                                        color: Colors.orange.shade300,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Availability toggle
                                      Row(
                                        children: [
                                          Switch(
                                            value: drone.isAvailable,
                                            onChanged:
                                                (value) =>
                                                    _toggleAvailability(drone),
                                          ),
                                          Text(
                                            drone.isAvailable
                                                ? 'Available'
                                                : 'Not Available',
                                            style: TextStyle(
                                              color:
                                                  drone.isAvailable
                                                      ? Colors.green
                                                      : Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Delete button
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        color: Colors.red,
                                        onPressed: () => _deleteDrone(drone.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return FutureBuilder<UserModel?>(
              future: context.read<AuthBloc>().getUserData(state.user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.role == 'Pilot') {
                  return FloatingActionButton(
                    onPressed: () => _showAddDroneBottomSheet(snapshot.data!),
                    child: const Icon(Icons.add),
                  );
                }
                return const SizedBox.shrink();
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
