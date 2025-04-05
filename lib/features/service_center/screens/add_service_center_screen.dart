import 'dart:io';
import 'package:drone_user_app/features/auth/bloc/auth_bloc.dart';
import 'package:drone_user_app/features/auth/models/user_model.dart';
import 'package:drone_user_app/features/service_center/models/service_center_model.dart';
import 'package:drone_user_app/features/service_center/repositories/service_center_repository.dart';
import 'package:drone_user_app/utils/file_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddServiceCenterScreen extends StatefulWidget {
  const AddServiceCenterScreen({super.key});

  @override
  State<AddServiceCenterScreen> createState() => _AddServiceCenterScreenState();
}

class _AddServiceCenterScreenState extends State<AddServiceCenterScreen> {
  final ServiceCenterRepository _repository = ServiceCenterRepository();
  final FileUploadService _fileUploadService = FileUploadService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _servicesController = TextEditingController();

  bool _isLoading = false;
  List<String> _services = [];
  List<File> _selectedImages = [];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _servicesController.dispose();
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

  Future<void> _submitForm(UserModel user) async {
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
        'service_centers/${user.uid}',
      );

      if (imageUrls.isEmpty) {
        throw Exception('Failed to upload images');
      }

      ServiceCenterModel serviceCenter = ServiceCenterModel(
        id: '', // Will be set by the repository
        ownerId: user.uid,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        email: _emailController.text.trim(),
        imageUrls: imageUrls,
        services: _services,
      );

      bool success = await _repository.addServiceCenter(serviceCenter);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service center added successfully')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add service center')),
        );
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

  void _addService() {
    if (_servicesController.text.isNotEmpty) {
      setState(() {
        _services.add(_servicesController.text.trim());
        _servicesController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Service Center')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return FutureBuilder<UserModel?>(
              future: context.read<AuthBloc>().getUserData(state.user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasData) {
                  UserModel user = snapshot.data!;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Service Center Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an address';
                              }
                              return null;
                            },
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _servicesController,
                                  decoration: const InputDecoration(
                                    labelText: 'Services Offered',
                                    border: OutlineInputBorder(),
                                    hintText: 'Enter a service',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _addService,
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_services.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _services.map((service) {
                                    return Chip(
                                      label: Text(service),
                                      onDeleted: () {
                                        setState(() {
                                          _services.remove(service);
                                        });
                                      },
                                    );
                                  }).toList(),
                            ),
                          const SizedBox(height: 24),

                          // Image Selection
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickImages,
                                  icon: const Icon(Icons.photo_library),
                                  label: Text(
                                    _selectedImages.isEmpty
                                        ? 'Select Images'
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
                          ElevatedButton(
                            onPressed:
                                _isLoading ? null : () => _submitForm(user),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child:
                                _isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text('Add Service Center'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return const Center(child: Text('Failed to load user data'));
              },
            );
          }
          return const Center(
            child: Text('You need to be logged in to add a service center'),
          );
        },
      ),
    );
  }
}
