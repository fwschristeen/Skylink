import 'dart:io';
import 'package:drone_user_app/features/auth/models/user_model.dart';
import 'package:drone_user_app/features/marketplace/models/product_model.dart';
import 'package:drone_user_app/features/marketplace/repositories/marketplace_repository.dart';
import 'package:drone_user_app/utils/file_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';

class EditProductBottomSheet extends StatefulWidget {
  final UserModel currentUser;
  final ProductModel product;

  const EditProductBottomSheet({
    super.key,
    required this.currentUser,
    required this.product,
  });

  @override
  State<EditProductBottomSheet> createState() => _EditProductBottomSheetState();
}

class _EditProductBottomSheetState extends State<EditProductBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  final _specsController = TextEditingController();
  final _repository = MarketplaceRepository();
  final _storage = FirebaseStorage.instance;
  final _imagePicker = ImagePicker();

  late ProductType _selectedType;
  late List<String> _imageUrls;
  String? _videoUrl;
  bool _isUploading = false;
  late Map<String, dynamic> _productSpecs;

  // Progress value notifier for tracking upload progress
  final ValueNotifier<double> _uploadProgress = ValueNotifier<double>(0.0);
  bool _isCompressing = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing product data
    _titleController = TextEditingController(text: widget.product.title);
    _descriptionController = TextEditingController(
      text: widget.product.description,
    );
    _priceController = TextEditingController(
      text: widget.product.price?.toString() ?? '',
    );
    _selectedType = widget.product.type;
    _imageUrls = widget.product.imageUrls?.toList() ?? [];
    _videoUrl = widget.product.videoUrl;
    _productSpecs =
        widget.product.specifications?.map(
          (key, value) => MapEntry(key, value),
        ) ??
        {};

    debugPrint('Editing product with ID: ${widget.product.id}');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _specsController.dispose();
    _uploadProgress.dispose();
    VideoCompress.cancelCompression();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isEmpty) return;

      setState(() {
        _isUploading = true;
      });

      for (var image in images) {
        final ref = _storage.ref().child(
          'products/${widget.currentUser.uid}/${const Uuid().v4()}.jpg',
        );
        await ref.putData(await image.readAsBytes());
        final url = await ref.getDownloadURL();
        setState(() {
          _imageUrls.add(url);
        });
      }

      setState(() {
        _isUploading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading images: $e')));
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      final ref = _storage.ref().child(
        'products/${widget.currentUser.uid}/${const Uuid().v4()}.jpg',
      );
      await ref.putData(await image.readAsBytes());
      final url = await ref.getDownloadURL();
      setState(() {
        _imageUrls = [url];
        _isUploading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (video == null) return;

      // Show uploading dialog with progress indicator
      if (!mounted) return;

      // Get file size before compression
      final File videoFile = File(video.path);
      final int originalSize = await videoFile.length();

      setState(() {
        _isUploading = true;
        _isCompressing = true;
      });

      // Show processing dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              title: Text('Processing Video'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Please wait while we optimize your video for upload.'),
                  SizedBox(height: 16),
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Compressing video...'),
                ],
              ),
            ),
      );

      // Compress video
      VideoCompress.setLogLevel(0);
      final MediaInfo? compressedInfo = await VideoCompress.compressVideo(
        video.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (!mounted || compressedInfo?.file == null) {
        setState(() {
          _isUploading = false;
          _isCompressing = false;
        });
        VideoCompress.deleteAllCache();
        return;
      }

      final File compressedFile = File(compressedInfo!.file!.path);
      final int compressedSize = await compressedFile.length();

      // Close compressing dialog and show upload dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isCompressing = false;
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) =>
                _buildUploadProgressDialog(originalSize, compressedSize),
      );

      // Upload to Firebase Storage with progress tracking
      final ref = _storage.ref().child(
        'products/${widget.currentUser.uid}/${const Uuid().v4()}.mp4',
      );

      // Only upload the compressed file
      final uploadTask = ref.putFile(
        compressedFile,
        SettableMetadata(
          contentType: 'video/mp4',
          customMetadata: {
            'originalFileName': video.name,
            'uploadedBy': widget.currentUser.name,
            'originalSize': '$originalSize',
            'compressedSize': '$compressedSize',
          },
        ),
      );

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        _uploadProgress.value = progress;
      });

      // Wait for upload completion
      await uploadTask.whenComplete(() {
        if (mounted) {
          Navigator.of(context).pop(); // Close progress dialog
        }
      });

      final url = await ref.getDownloadURL();
      setState(() {
        _videoUrl = url;
        _isUploading = false;
      });

      // Clean up compression cache
      VideoCompress.deleteAllCache();

      if (mounted) {
        final compressionRate = ((originalSize - compressedSize) /
                originalSize *
                100)
            .toStringAsFixed(1);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Video uploaded successfully! Compressed by $compressionRate%',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog if open
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading video: $e')));
      }
      setState(() {
        _isUploading = false;
        _isCompressing = false;
      });

      // Clean up on error
      VideoCompress.deleteAllCache();
    }
  }

  // Build upload progress dialog with percentage
  Widget _buildUploadProgressDialog(int originalSize, int compressedSize) {
    final originalSizeInMb = (originalSize / (1024 * 1024)).toStringAsFixed(2);
    final compressedSizeInMb = (compressedSize / (1024 * 1024)).toStringAsFixed(
      2,
    );
    final savingsPercent = ((originalSize - compressedSize) /
            originalSize *
            100)
        .toStringAsFixed(1);

    return AlertDialog(
      title: const Text('Uploading Video'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Please wait while we upload your video.'),
          const SizedBox(height: 8),
          Text('Original size: $originalSizeInMb MB'),
          Text(
            'Compressed size: $compressedSizeInMb MB (saved $savingsPercent%)',
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<double>(
            valueListenable: _uploadProgress,
            builder: (context, value, _) {
              final percentage = (value * 100).toInt();
              return Column(
                children: [
                  LinearProgressIndicator(value: value),
                  const SizedBox(height: 8),
                  Text('Uploading: $percentage%'),
                ],
              );
            },
          ),
        ],
      ),
    );
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
              _productSpecs[key] = value;
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
      _productSpecs.remove(key);
    });
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == ProductType.drone && _imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    if (_selectedType == ProductType.image && _imageUrls.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please add an image')));
      return;
    }

    if (_selectedType == ProductType.video && _videoUrl == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please add a video')));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Update the product with new data while keeping the same ID
      final updatedProduct = ProductModel(
        id: widget.product.id,
        title: _titleController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        imageUrls: _selectedType != ProductType.video ? _imageUrls : null,
        videoUrl: _selectedType == ProductType.video ? _videoUrl : null,
        type: _selectedType,
        sellerId: widget.product.sellerId,
        sellerName: widget.product.sellerName,
        createdAt: widget.product.createdAt, // Keep original creation date
        specifications: _productSpecs.isNotEmpty ? _productSpecs : null,
      );

      debugPrint('Updating product with ID: ${updatedProduct.id}');
      await _repository.updateProduct(updatedProduct);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating product: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Edit Product',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ProductType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Product Type',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      ProductType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.toString().split('.').last),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                        if (value == ProductType.video) {
                          _imageUrls = [];
                        } else {
                          _videoUrl = null;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
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
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                    prefixText: 'LKR ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedType == ProductType.drone) ...[
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Change Images'),
                  ),
                  if (_imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imageUrls.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Image.network(
                                  _imageUrls[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 12,
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _imageUrls.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ] else if (_selectedType == ProductType.image) ...[
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickImage,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Change Image'),
                  ),
                  if (_imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Image.network(
                          _imageUrls.first,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _imageUrls.clear();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Change Video'),
                  ),
                  if (_videoUrl != null) ...[
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 200,
                          color: Colors.black,
                          child: const Center(
                            child: Icon(
                              Icons.videocam,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _videoUrl = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Product Specifications:',
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
                    if (_productSpecs.isNotEmpty) ...[
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
                                  _productSpecs.entries.map((entry) {
                                    return Chip(
                                      label: Text(
                                        '${entry.key}: ${entry.value}',
                                      ),
                                      deleteIcon: const Icon(
                                        Icons.close,
                                        size: 18,
                                      ),
                                      onDeleted: () => _removeSpec(entry.key),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isUploading ? null : _updateProduct,
                  child:
                      _isUploading
                          ? const CircularProgressIndicator()
                          : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
