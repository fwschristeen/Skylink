import 'package:drone_user_app/features/auth/bloc/auth_bloc.dart';
import 'package:drone_user_app/features/service_center/models/service_center_model.dart';
import 'package:drone_user_app/features/service_center/repositories/service_center_repository.dart';
import 'package:drone_user_app/features/service_center/widgets/service_center_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyServiceCentersScreen extends StatefulWidget {
  const MyServiceCentersScreen({super.key});

  @override
  State<MyServiceCentersScreen> createState() => _MyServiceCentersScreenState();
}

class _MyServiceCentersScreenState extends State<MyServiceCentersScreen> {
  final ServiceCenterRepository _repository = ServiceCenterRepository();
  bool _isLoading = false;
  List<ServiceCenterModel> _serviceCenters = [];

  @override
  void initState() {
    super.initState();
    _loadUserServiceCenters();
  }

  Future<void> _loadUserServiceCenters() async {
    setState(() {
      _isLoading = true;
    });

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final userId = authState.user.uid;
      try {
        final serviceCenters = await _repository.getUserServiceCenters(userId);
        if (mounted) {
          setState(() {
            _serviceCenters = serviceCenters;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading service centers: $e')),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteServiceCenter(String serviceCenterId) async {
    try {
      final success = await _repository.deleteServiceCenter(serviceCenterId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service center deleted successfully')),
        );
        _loadUserServiceCenters();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete service center')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_serviceCenters.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'You don\'t have any service centers yet',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/add-service-center',
                        ).then((_) => _loadUserServiceCenters());
                      },
                      child: const Text('Add Service Center'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _loadUserServiceCenters,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: _serviceCenters.length,
                  itemBuilder: (context, index) {
                    final serviceCenter = _serviceCenters[index];
                    return Dismissible(
                      key: Key(serviceCenter.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: Text(
                                'Are you sure you want to delete "${serviceCenter.name}"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        _deleteServiceCenter(serviceCenter.id);
                      },
                      child: ServiceCenterCard(
                        serviceCenter: serviceCenter,
                        onTap: () {
                          // Navigate to edit service center screen
                          Navigator.pushNamed(
                            context,
                            '/edit-service-center',
                            arguments: serviceCenter,
                          ).then((_) => _loadUserServiceCenters());
                        },
                      ),
                    );
                  },
                ),
              ),
            );
          }

          return const Center(
            child: Text(
              'You need to be logged in to view your service centers',
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/add-service-center',
          ).then((_) => _loadUserServiceCenters());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
