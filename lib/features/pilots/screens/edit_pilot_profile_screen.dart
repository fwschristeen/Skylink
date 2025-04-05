import 'dart:io';
import 'package:drone_user_app/features/auth/bloc/auth_bloc.dart';
import 'package:drone_user_app/features/auth/models/user_model.dart';
import 'package:drone_user_app/features/pilots/models/pilot_model.dart';
import 'package:drone_user_app/features/pilots/repositories/pilot_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class EditPilotProfileScreen extends StatefulWidget {
  final PilotModel? existingProfile;

  const EditPilotProfileScreen({super.key, this.existingProfile});

  @override
  State<EditPilotProfileScreen> createState() => _EditPilotProfileScreenState();
}

class _EditPilotProfileScreenState extends State<EditPilotProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pilotRepository = PilotRepository();
  final _imagePicker = ImagePicker();
  final _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _hourlyRateController;
  late TextEditingController _experienceController;
  late TextEditingController _skillController;
  late TextEditingController _caAslLicenceController;

  // State variables
  List<String> _skills = [];
  List<String> _certificateUrls = [];
  File? _profileImage;
  bool _isAvailable = true;
  bool _isLoading = false;
  String? _profileImageUrl;
  List<File> _newCertificateFiles = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingProfile();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
    _hourlyRateController = TextEditingController();
    _experienceController = TextEditingController();
    _skillController = TextEditingController();
    _caAslLicenceController = TextEditingController();
  }

  void _loadExistingProfile() {
    if (widget.existingProfile != null) {
      final pilot = widget.existingProfile!;

      _nameController.text = pilot.name ?? '';
      _emailController.text = pilot.email ?? '';
      _phoneController.text = pilot.phoneNumber ?? '';
      _descriptionController.text = pilot.description ?? '';
      _locationController.text = pilot.location ?? '';
      _hourlyRateController.text = pilot.hourlyRate?.toString() ?? '';
      _experienceController.text = pilot.experience?.toString() ?? '';
      _caAslLicenceController.text = pilot.caAslLicenceNo ?? '';

      setState(() {
        _skills = pilot.skills ?? [];
        _certificateUrls = pilot.certificateUrls ?? [];
        _isAvailable = pilot.isAvailable;
        _profileImageUrl = pilot.imageUrl;
      });
    } else {
      // For new profile, pre-fill with user data if available
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        context.read<AuthBloc>().getUserData(authState.user.uid).then((
          userData,
        ) {
          if (userData != null && mounted) {
            setState(() {
              _nameController.text = userData.name;
              _emailController.text = userData.email;
              _profileImageUrl = userData.imageUrl;
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _hourlyRateController.dispose();
    _experienceController.dispose();
    _skillController.dispose();
    _caAslLicenceController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _pickCertificateImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _newCertificateFiles.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking certificate: $e')));
    }
  }

  void _addSkill() {
    if (_skillController.text.trim().isNotEmpty) {
      setState(() {
        _skills.add(_skillController.text.trim());
        _skillController.clear();
      });
    }
  }

  void _removeSkill(int index) {
    setState(() {
      _skills.removeAt(index);
    });
  }

  void _removeCertificateUrl(int index) {
    setState(() {
      _certificateUrls.removeAt(index);
    });
  }

  void _removeNewCertificate(int index) {
    setState(() {
      _newCertificateFiles.removeAt(index);
    });
  }

  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null) return _profileImageUrl;

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) return null;

      final userId = authState.user.uid;
      final ref = _storage.ref().child(
        'profile_images/$userId/${_uuid.v4()}.jpg',
      );

      await ref.putFile(_profileImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  Future<List<String>> _uploadCertificates() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return [];

    final userId = authState.user.uid;
    final List<String> newUrls = [];

    try {
      // Upload each new certificate
      for (final file in _newCertificateFiles) {
        final ref = _storage.ref().child(
          'certificates/$userId/${_uuid.v4()}.jpg',
        );
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        newUrls.add(url);
      }
    } catch (e) {
      debugPrint('Error uploading certificates: $e');
    }

    // Combine existing and new URLs
    return [..._certificateUrls, ...newUrls];
  }

  Future<void> _savePilotProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('You must be logged in to save profile');
      }

      final userId = authState.user.uid;

      // Upload images
      final profileImageUrl = await _uploadProfileImage();
      final certificateUrls = await _uploadCertificates();

      // Create pilot model
      final pilot = PilotModel(
        id: widget.existingProfile?.id ?? userId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        imageUrl: profileImageUrl,
        description: _descriptionController.text.trim(),
        skills: _skills,
        hourlyRate:
            _hourlyRateController.text.isNotEmpty
                ? double.tryParse(_hourlyRateController.text.trim())
                : null,
        isAvailable: _isAvailable,
        rating: widget.existingProfile?.rating,
        reviewCount: widget.existingProfile?.reviewCount,
        certificateUrls: certificateUrls,
        location: _locationController.text.trim(),
        experience:
            _experienceController.text.isNotEmpty
                ? int.tryParse(_experienceController.text.trim())
                : null,
        caAslLicenceNo: _caAslLicenceController.text.trim(),
      );

      // Save to Firestore
      bool success;
      if (widget.existingProfile != null) {
        success = await _pilotRepository.updatePilot(pilot);
      } else {
        success = await _pilotRepository.addPilot(pilot);
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pilot profile saved successfully')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save pilot profile')),
          );
        }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingProfile != null
              ? 'Edit Pilot Profile'
              : 'Create Pilot Profile',
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Image
                      Center(
                        child: GestureDetector(
                          onTap: _pickProfileImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                backgroundImage:
                                    _profileImage != null
                                        ? FileImage(_profileImage!)
                                        : (_profileImageUrl != null
                                            ? NetworkImage(_profileImageUrl!)
                                                as ImageProvider
                                            : null),
                                child:
                                    (_profileImage == null &&
                                            _profileImageUrl == null)
                                        ? const Icon(Icons.person, size: 60)
                                        : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Basic Information
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _caAslLicenceController,
                        decoration: const InputDecoration(
                          labelText: 'CAASL Licence Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your CAASL licence number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Professional Details
                      const Text(
                        'Professional Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _experienceController,
                        decoration: const InputDecoration(
                          labelText: 'Years of Experience',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your experience';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _hourlyRateController,
                        decoration: const InputDecoration(
                          labelText: 'Hourly Rate (LKR)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your hourly rate';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      SwitchListTile(
                        title: const Text('Available for Hire'),
                        value: _isAvailable,
                        onChanged: (bool value) {
                          setState(() {
                            _isAvailable = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'About Me / Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please provide a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Skills
                      const Text(
                        'Skills',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _skillController,
                              decoration: const InputDecoration(
                                labelText: 'Add Skill',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addSkill,
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_skills.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            _skills.length,
                            (index) => Chip(
                              label: Text(_skills[index]),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () => _removeSkill(index),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Certificates
                      const Text(
                        'Certificates',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        onPressed: _pickCertificateImage,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Certificate'),
                      ),
                      const SizedBox(height: 16),

                      // Existing certificates
                      if (_certificateUrls.isNotEmpty) ...[
                        const Text('Existing Certificates:'),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _certificateUrls.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 120,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    child: Image.network(
                                      _certificateUrls[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => _removeCertificateUrl(index),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // New certificates
                      if (_newCertificateFiles.isNotEmpty) ...[
                        const Text('New Certificates:'),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _newCertificateFiles.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 120,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    child: Image.file(
                                      _newCertificateFiles[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => _removeNewCertificate(index),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _savePilotProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('Save Profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
