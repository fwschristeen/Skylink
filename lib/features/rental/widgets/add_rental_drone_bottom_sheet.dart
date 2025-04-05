import 'dart:io';
import 'package:drone_user_app/features/auth/models/user_model.dart';
import 'package:drone_user_app/features/rental/models/drone_rental_model.dart';
import 'package:drone_user_app/features/rental/repositories/rental_repository.dart';
import 'package:drone_user_app/utils/file_upload_service.dart';
import 'package:flutter/material.dart';

class AddRentalDroneBottomSheet extends StatefulWidget {
  final UserModel currentUser;

  const AddRentalDroneBottomSheet({super.key, required this.currentUser});

  @override
  State<AddRentalDroneBottomSheet> createState() =>
      _AddRentalDroneBottomSheetState();
}

class _AddRentalDroneBottomSheetState extends State<AddRentalDroneBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pricePerDayController = TextEditingController();
  final _specsController = TextEditingController();

  final RentalRepository _repository = RentalRepository();
  final FileUploadService _fileUploadService = FileUploadService();

  List<File> _selectedImages = [];
  Map<String, dynamic> _droneSpecs = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pricePerDayController.dispose();
    _specsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _fileUploadService.pickMultipleImages();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images;
      });
    }
  }

  void _addSpec() {
    if (_specsController.text.isNotEmpty) {
      final text = _specsController.text.trim();
      if (text.contains(':')) {
        final parts = text.split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          // Join all parts after the first colon in case value contains colons
          final value = parts.sublist(1).join(':').trim();

          if (key.isNotEmpty && value.isNotEmpty) {
            setState(() {
              _droneSpecs[key] = value;
              _specsController.clear();
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Both key and value must not be empty'),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid format. Use "Key: Value"')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid format. Use "Key: Value"')),
        );
      }
    }
  }

  void _removeSpec(String key) {
    setState(() {
      _droneSpecs.remove(key);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload images to Firebase Storage
      final imageUrls = await _fileUploadService.uploadMultipleFiles(
        _selectedImages,
        'rentals/drones',
      );

      if (imageUrls.isEmpty) {
        throw Exception('Failed to upload images');
      }

      // Create drone rental model
      final drone = DroneRentalModel(
        id: '', // Will be set by repository
        ownerId: widget.currentUser.uid,
        ownerName: widget.currentUser.name,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        pricePerDay: double.parse(_pricePerDayController.text.trim()),
        imageUrls: imageUrls,
        specs: _droneSpecs,
        isAvailable: true,
      );

      // Add drone to Firestore
      final success = await _repository.addDroneForRent(drone);

      if (success && mounted) {
        Navigator.pop(context, true); // Close bottom sheet with success
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to add drone')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add Drone for Rent',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Drone Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Drone Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Drone Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price Per Day
              TextFormField(
                controller: _pricePerDayController,
                decoration: const InputDecoration(
                  labelText: 'Price Per Day',
                  prefixText: 'LKR ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  try {
                    double.parse(value);
                  } catch (e) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Drone Specs
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Drone Specifications:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _specsController,
                          decoration: const InputDecoration(
                            labelText: 'Add Specification',
                            hintText: 'e.g. Weight: 500g',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addSpec,
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),

              // Display added specs
              if (_droneSpecs.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade700),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Added Specifications:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _droneSpecs.entries.map((entry) {
                              return Chip(
                                label: Text('${entry.key}: ${entry.value}'),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () => _removeSpec(entry.key),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Image Selection
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.photo_library),
                      label: Text(
                        _selectedImages.isEmpty
                            ? 'Select Drone Images'
                            : '${_selectedImages.length} Images Selected',
                      ),
                    ),
                  ),
                ],
              ),

              // Display selected images preview
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            Image.file(
                              _selectedImages[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  color: Colors.black54,
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Add Drone for Rent'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
