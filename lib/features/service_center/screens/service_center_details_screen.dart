import 'package:drone_user_app/features/auth/bloc/auth_bloc.dart';
import 'package:drone_user_app/features/service_center/models/service_center_model.dart';
import 'package:drone_user_app/features/service_center/repositories/service_center_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceCenterDetailsScreen extends StatefulWidget {
  final ServiceCenterModel serviceCenter;

  const ServiceCenterDetailsScreen({super.key, required this.serviceCenter});

  @override
  State<ServiceCenterDetailsScreen> createState() =>
      _ServiceCenterDetailsScreenState();
}

class _ServiceCenterDetailsScreenState
    extends State<ServiceCenterDetailsScreen> {
  final ServiceCenterRepository _repository = ServiceCenterRepository();
  final _reviewTextController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _rating = 5.0;
  bool _isSubmittingReview = false;
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _reviewTextController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmittingReview = true;
    });

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      try {
        final success = await _repository.addReview(
          widget.serviceCenter.id,
          _rating,
          _reviewTextController.text.trim(),
          authState.user.uid,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review submitted successfully')),
          );
          _reviewTextController.clear();
          setState(() {
            _rating = 5.0;
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit review')),
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
            _isSubmittingReview = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a review')),
      );
      setState(() {
        _isSubmittingReview = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(background: _buildImageCarousel()),
          ),

          // Content
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Center Name and Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.serviceCenter.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (widget.serviceCenter.rating != null)
                          _buildRatingIndicator(
                            widget.serviceCenter.rating!,
                            widget.serviceCenter.reviewCount ?? 0,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Address
                    _buildInfoRow(
                      Icons.location_on,
                      widget.serviceCenter.address,
                    ),
                    const SizedBox(height: 12),

                    // Phone
                    _buildInfoRow(
                      Icons.phone,
                      widget.serviceCenter.phoneNumber,
                      onTap:
                          () => _launchPhoneCall(
                            widget.serviceCenter.phoneNumber,
                          ),
                    ),
                    const SizedBox(height: 12),

                    // Email
                    _buildInfoRow(
                      Icons.email,
                      widget.serviceCenter.email,
                      onTap: () => _launchEmail(widget.serviceCenter.email),
                    ),
                    const SizedBox(height: 24),

                    // Description
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.serviceCenter.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade300,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Services
                    const Text(
                      'Services Offered',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          widget.serviceCenter.services.map((service) {
                            return Chip(
                              label: Text(service),
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Reviews Section
                    const Text(
                      'Reviews',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Write a review
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is Authenticated) {
                          return _buildReviewForm();
                        } else {
                          return GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/login'),
                            child: const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login),
                                    SizedBox(width: 8),
                                    Text('Log in to leave a review'),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Reviews list
                    _buildReviewsList(),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return PageView.builder(
      itemCount: widget.serviceCenter.imageUrls.length,
      onPageChanged: (index) {
        setState(() {
          _currentImageIndex = index;
        });
      },
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                widget.serviceCenter.imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade800,
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade800,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
            if (widget.serviceCenter.imageUrls.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.serviceCenter.imageUrls.length,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            i == _currentImageIndex
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRatingIndicator(double rating, int reviewCount) {
    return Row(
      children: [
        Icon(Icons.star, color: Colors.amber.shade700, size: 20),
        const SizedBox(width: 4),
        Text(
          '${rating.toStringAsFixed(1)} ($reviewCount)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color:
                    onTap != null ? Colors.blue.shade400 : Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Write a Review',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Rating Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Rating: '),
                  const SizedBox(width: 8),
                  Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _rating.toString(),
                    onChanged: (value) {
                      setState(() {
                        _rating = value;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              // Review Text
              TextFormField(
                controller: _reviewTextController,
                decoration: const InputDecoration(
                  labelText: 'Your Review',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your review';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmittingReview ? null : _submitReview,
                  child:
                      _isSubmittingReview
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Submit Review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('reviews')
              .where('serviceCenterId', isEqualTo: widget.serviceCenter.id)
              .orderBy('createdAt', descending: true)
              .limit(10)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading reviews: ${snapshot.error}'),
          );
        }

        final reviews = snapshot.data?.docs ?? [];

        if (reviews.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('No reviews yet. Be the first to review!'),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index].data() as Map<String, dynamic>;
            final Timestamp? timestamp = review['createdAt'] as Timestamp?;
            final DateTime reviewDate = timestamp?.toDate() ?? DateTime.now();

            return Card(
              margin: const EdgeInsets.only(bottom: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FutureBuilder<String>(
                          future: _getUserName(review['userId']),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ?? 'Anonymous',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                        Text(
                          '${_formatDate(reviewDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (review['rating'] as num).toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(review['reviewText'] as String),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String> _getUserName(String userId) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        return userData?['name'] ?? 'Anonymous';
      }
      return 'Anonymous';
    } catch (e) {
      return 'Anonymous';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _launchPhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone: $phoneNumber')),
        );
      }
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: encodeQueryParameters(<String, String>{
        'subject': 'Inquiry about your service center',
      }),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch email: $email')),
        );
      }
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }
}
