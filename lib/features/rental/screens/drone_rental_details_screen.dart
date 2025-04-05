import 'package:drone_user_app/features/auth/bloc/auth_bloc.dart';
import 'package:drone_user_app/features/rental/models/drone_rental_model.dart';
import 'package:drone_user_app/features/rental/repositories/rental_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class DroneRentalDetailsScreen extends StatefulWidget {
  const DroneRentalDetailsScreen({super.key});

  @override
  State<DroneRentalDetailsScreen> createState() =>
      _DroneRentalDetailsScreenState();
}

class _DroneRentalDetailsScreenState extends State<DroneRentalDetailsScreen> {
  late DroneRentalModel _drone;
  bool _isInitialized = false;
  bool _isOwner = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Selected dates for booking
  DateTime? _startDate;
  DateTime? _endDate;
  List<DateTime> _bookedDates = [];

  // Calculate number of days and total price
  int _numberOfDays = 0;
  double _totalPrice = 0;

  final RentalRepository _repository = RentalRepository();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _drone = ModalRoute.of(context)!.settings.arguments as DroneRentalModel;
      _checkIfOwner();
      _loadBookedDates();
      _isInitialized = true;
    }
  }

  Future<void> _checkIfOwner() async {
    final state = context.read<AuthBloc>().state;
    if (state is Authenticated) {
      setState(() {
        _isOwner = state.user.uid == _drone.ownerId;
      });
    }
  }

  void _loadBookedDates() {
    if (_drone.bookedDates != null) {
      setState(() {
        _bookedDates = List.from(_drone.bookedDates!);
      });
    }
  }

  void _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime day) {
        // Disable already booked dates
        return !_bookedDates.any(
          (bookedDate) =>
              bookedDate.year == day.year &&
              bookedDate.month == day.month &&
              bookedDate.day == day.day,
        );
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[800],
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Reset end date if it's before start date
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
        _calculateBookingDetails();
      });
    }
  }

  void _selectEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date first')),
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime day) {
        // Disable already booked dates
        return !_bookedDates.any(
          (bookedDate) =>
              bookedDate.year == day.year &&
              bookedDate.month == day.month &&
              bookedDate.day == day.day,
        );
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[800],
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
        _calculateBookingDetails();
      });
    }
  }

  void _calculateBookingDetails() {
    if (_startDate != null && _endDate != null) {
      setState(() {
        _numberOfDays = _endDate!.difference(_startDate!).inDays + 1;
        _totalPrice = _numberOfDays * _drone.pricePerDay;
      });
    } else if (_startDate != null) {
      setState(() {
        _numberOfDays = 1;
        _totalPrice = _drone.pricePerDay;
      });
    } else {
      setState(() {
        _numberOfDays = 0;
        _totalPrice = 0;
      });
    }
  }

  List<DateTime> _getDatesToBook() {
    List<DateTime> dates = [];

    if (_startDate != null && _endDate != null) {
      // Add all dates between start and end
      for (int i = 0; i <= _endDate!.difference(_startDate!).inDays; i++) {
        dates.add(_startDate!.add(Duration(days: i)));
      }
    } else if (_startDate != null) {
      // Just the start date
      dates.add(_startDate!);
    }

    return dates;
  }

  Future<void> _bookDrone() async {
    final state = context.read<AuthBloc>().state;
    if (state is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to book a drone')),
      );
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least a start date')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dates = _getDatesToBook();
      final success = await _repository.bookDrone(
        _drone.id,
        dates,
        state.user.uid,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Drone booked successfully!')),
        );

        // Update local booked dates
        setState(() {
          _bookedDates.addAll(dates);
          _startDate = null;
          _endDate = null;
          _numberOfDays = 0;
          _totalPrice = 0;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to book drone. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _contactOwner() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Contact Owner',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    _drone.ownerName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Drone Owner',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.white),
                  title: const Text(
                    'Call Owner',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    // This is a placeholder since we don't have the owner's phone in the model
                    final Uri phoneUri = Uri(
                      scheme: 'tel',
                      path: '+9477123456',
                    );
                    if (await canLaunchUrl(phoneUri)) {
                      await launchUrl(phoneUri);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.white),
                  title: const Text(
                    'Email Owner',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    // This is a placeholder since we don't have the owner's email in the model
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: 'owner@example.com',
                      queryParameters: {
                        'subject': 'Regarding your drone: ${_drone.title}',
                      },
                    );
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Drone Details',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCarousel(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!_drone.isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'UNAVAILABLE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          _drone.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By ${_drone.ownerName}',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'LKR ${_drone.pricePerDay.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Text(
                        ' / day',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _drone.description,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),

                  if (_drone.specs.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Specifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        border: Border.all(color: Colors.grey.shade800),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children:
                            _drone.specs.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${entry.key}:',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        entry.value.toString(),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],

                  if (!_isOwner && _drone.isAvailable) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'Book This Drone',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date selection
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectStartDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade700),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Start Date',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _startDate != null
                                        ? DateFormat(
                                          'MMM dd, yyyy',
                                        ).format(_startDate!)
                                        : 'Select',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          _startDate != null
                                              ? Colors.white
                                              : Colors.white38,
                                      fontWeight:
                                          _startDate != null
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectEndDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade700),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'End Date',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _endDate != null
                                        ? DateFormat(
                                          'MMM dd, yyyy',
                                        ).format(_endDate!)
                                        : 'Select',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          _endDate != null
                                              ? Colors.white
                                              : Colors.white38,
                                      fontWeight:
                                          _endDate != null
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_totalPrice > 0) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Number of days:',
                                  style: TextStyle(color: Colors.white),
                                ),
                                Text(
                                  '$_numberOfDays ${_numberOfDays == 1 ? 'day' : 'days'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Price per day:',
                                  style: TextStyle(color: Colors.white),
                                ),
                                Text(
                                  'LKR ${_drone.pricePerDay.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24, height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total price:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'LKR ${_totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.red.withOpacity(0.2),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _bookDrone,
                            icon:
                                _isLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Icon(Icons.calendar_today),
                            label: Text(
                              _isLoading ? 'Processing...' : 'Book Now',
                            ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              disabledForegroundColor: Colors.white60,
                              disabledBackgroundColor: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: _contactOwner,
                          icon: const Icon(Icons.message, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (!_isOwner && !_drone.isAvailable) ...[
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.not_interested,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'This drone is currently unavailable for rent',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _contactOwner,
                            icon: const Icon(Icons.contact_mail),
                            label: const Text('Contact Owner'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_isOwner) ...[
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You are the owner of this drone listing',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You can manage this listing from the "My Drones" section',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (_drone.imageUrls.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey.shade900,
        child: const Center(
          child: Icon(Icons.flight, size: 64, color: Colors.white54),
        ),
      );
    }

    final PageController controller = PageController();
    final ValueNotifier<int> currentPageNotifier = ValueNotifier<int>(0);

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: controller,
            itemCount: _drone.imageUrls.length,
            onPageChanged: (index) {
              currentPageNotifier.value = index;
            },
            itemBuilder: (context, index) {
              return Image.network(
                _drone.imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade900,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.white54,
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade900,
                    child: Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                        color: Colors.white70,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (_drone.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ValueListenableBuilder<int>(
              valueListenable: currentPageNotifier,
              builder: (context, value, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _drone.imageUrls.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            value == index
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
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
}
