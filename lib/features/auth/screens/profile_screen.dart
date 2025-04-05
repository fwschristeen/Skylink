import 'dart:io';
import 'package:drone_user_app/features/auth/bloc/auth_bloc.dart';
import 'package:drone_user_app/features/auth/models/user_model.dart';
import 'package:drone_user_app/features/pilots/repositories/pilot_repository.dart';
import 'package:drone_user_app/features/pilots/screens/edit_pilot_profile_screen.dart';
import 'package:drone_user_app/utils/file_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  final FileUploadService _fileUploadService = FileUploadService();
  File? _selectedImage;
  bool _isLoading = false;
  bool _isEditMode = false;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final userData = await context.read<AuthBloc>().getUserData(
        authState.user.uid,
      );
      if (userData != null && mounted) {
        setState(() {
          _user = userData;
          _nameController.text = userData.name;
          _emailController.text = userData.email;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated && _user != null) {
        String? imageUrl = _user!.imageUrl;

        // Upload new image if selected
        if (_selectedImage != null) {
          final uploadedUrl = await _fileUploadService.uploadFile(
            _selectedImage!,
            'profile_images/${authState.user.uid}',
          );

          if (uploadedUrl != null) {
            imageUrl = uploadedUrl;
          }
        }

        // Create updated user model
        final updatedUser = UserModel(
          uid: _user!.uid,
          name: _nameController.text.trim(),
          email: _user!.email, // Email shouldn't be editable
          role: _user!.role,
          imageUrl: imageUrl,
        );

        // Update user in database
        final success = await context.read<AuthBloc>().updateUserData(
          updatedUser,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          setState(() {
            _isEditMode = false;
            _user = updatedUser;
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToPilotProfileEdit(BuildContext context) async {
    final pilotRepository = PilotRepository();

    try {
      // Check if pilot profile exists
      final pilotProfile = await pilotRepository.getPilotById(_user!.uid);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  EditPilotProfileScreen(existingProfile: pilotProfile),
        ),
      ).then((updated) {
        if (updated == true) {
          // Refresh the user data if pilot profile was updated
          _loadUserData();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pilot profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutConfirmation(context);
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // Profile Image
                  GestureDetector(
                    onTap: _isEditMode ? _pickImage : null,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.2),
                          backgroundImage:
                              _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : (_user?.imageUrl != null &&
                                          _user!.imageUrl!.isNotEmpty
                                      ? NetworkImage(_user!.imageUrl!)
                                          as ImageProvider
                                      : null),
                          child:
                              (_selectedImage == null &&
                                      (_user?.imageUrl == null ||
                                          _user!.imageUrl!.isEmpty))
                                  ? const Icon(Icons.person, size: 60)
                                  : null,
                        ),
                        if (_isEditMode)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              radius: 18,
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // User Role Badge
                  if (_user != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _user!.role,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Role-Specific Actions
                  if (_user != null && _user!.role == 'Pilot')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilot Options',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToPilotProfileEdit(context),
                          icon: const Icon(Icons.edit_document),
                          label: const Text('Edit Pilot Profile'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: const Size(double.infinity, 0),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // User Details Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          enabled: _isEditMode,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
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
                            prefixIcon: Icon(Icons.email),
                          ),
                          enabled: false, // Email shouldn't be editable
                        ),
                        const SizedBox(height: 24),

                        if (_isEditMode) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _updateProfile,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child:
                                      _isLoading
                                          ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Text('Save Changes'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              OutlinedButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : () {
                                          setState(() {
                                            _isEditMode = false;
                                            _selectedImage = null;
                                            _nameController.text =
                                                _user?.name ?? '';
                                          });
                                        },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ] else ...[
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isEditMode = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: const Size(double.infinity, 0),
                            ),
                            child: const Text('Edit Profile'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return const Center(
            child: Text('Please log in to view your profile'),
          );
        },
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<AuthBloc>().add(LogoutEvent());
                  Navigator.of(context).pushReplacementNamed('/');
                },
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }
}
