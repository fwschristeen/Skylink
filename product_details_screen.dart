import 'package:drone_user_app/features/auth/bloc/auth_bloc.dart';
import 'package:drone_user_app/features/marketplace/models/product_model.dart';
import 'package:drone_user_app/features/marketplace/widgets/video_thumbnail_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late ProductModel _product;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  int _currentImageIndex = 0;
  bool _isInitialized = false;
  bool _isSeller = false;
  bool _isVideoLoading = false;
  bool _videoError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _product = ModalRoute.of(context)!.settings.arguments as ProductModel;
      _checkIfSeller();
      _initializeVideo();
      _isInitialized = true;
    }
  }

  Future<void> _checkIfSeller() async {
    final state = context.read<AuthBloc>().state;
    if (state is Authenticated) {
      setState(() {
        _isSeller = state.user.uid == _product.sellerId;
      });
    }
  }

  void _contactSeller() {
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
                  'Contact Seller',
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
                    _product.sellerName ?? 'Unknown Seller',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Seller',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.white),
                  title: const Text(
                    'Call Seller',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    // This is a placeholder since we don't have the seller's phone in the model yet
                    // In a real app, you'd use the seller's actual phone number
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
                    'Email Seller',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    // This is a placeholder since we don't have the seller's email in the model yet
                    // In a real app, you'd use the seller's actual email
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: 'seller@example.com',
                      queryParameters: {
                        'subject': 'Regarding your product: ${_product.title}',
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

  Future<void> _initializeVideo() async {
    if (_product.type == ProductType.video && _product.videoUrl != null) {
      setState(() {
        _isVideoLoading = true;
        _videoError = false;
      });

      try {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(_product.videoUrl!),
        );

        await _videoController!.initialize();

        // Explicitly pause the video to prevent auto-playing
        _videoController!.pause();

        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: false,
          looping: false,
          aspectRatio: 16 / 9,
          allowFullScreen: false,
          allowMuting: true,
          showControls: true,
          placeholder: const Center(
            child: CircularProgressIndicator(color: Colors.white70),
          ),
        );

        setState(() {
          _isVideoLoading = false;
        });
      } catch (e) {
        debugPrint('Error initializing video: $e');
        setState(() {
          _isVideoLoading = false;
          _videoError = true;
          _videoController?.dispose();
          _videoController = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Product Details',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMediaSection(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _product.title ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By ${_product.sellerName ?? 'Unknown Seller'}',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'LKR ${_product.price?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
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
                    _product.description ?? 'No description available',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  if (_product.specifications != null &&
                      _product.specifications!.isNotEmpty) ...[
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
                            _product.specifications!.entries.map((entry) {
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
                  if (!_isSeller) ...[
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _contactSeller,
                        icon: const Icon(Icons.contact_mail),
                        label: const Text('Contact Seller'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
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

  Widget _buildMediaSection() {
    if (_product.type == ProductType.video) {
      if (_isVideoLoading) {
        return Container(
          height: 300,
          color: Colors.grey.shade900,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white70),
          ),
        );
      }

      if (_videoError) {
        return Container(
          height: 300,
          color: Colors.grey.shade900,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Failed to load video',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _initializeVideo,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blueGrey,
                ),
              ),
            ],
          ),
        );
      }

      if (_chewieController != null) {
        return SizedBox(
          height: 300,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Chewie(controller: _chewieController!),
          ),
        );
      }
    }

    // Handle image products
    if (_product.imageUrls == null || _product.imageUrls!.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey.shade900,
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            size: 64,
            color: Colors.white54,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: _product.imageUrls!.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                _product.imageUrls![index],
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
        if (_product.imageUrls!.length > 1)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _product.imageUrls!.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _currentImageIndex == index
                            ? Theme.of(context).primaryColor
                            : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
