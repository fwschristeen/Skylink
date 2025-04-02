import 'dart:io';
import 'package:drone_user_app/features/auth/bloc/auth_bloc.dart';
import 'package:drone_user_app/features/auth/models/user_model.dart';
import 'package:drone_user_app/features/marketplace/models/product_model.dart';
import 'package:drone_user_app/features/marketplace/repositories/marketplace_repository.dart';
import 'package:drone_user_app/features/marketplace/widgets/add_product_bottom_sheet.dart';
import 'package:drone_user_app/features/marketplace/widgets/edit_product_bottom_sheet.dart';
import 'package:drone_user_app/features/marketplace/widgets/product_card.dart';
import 'package:drone_user_app/features/marketplace/widgets/video_thumbnail_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final MarketplaceRepository _repository = MarketplaceRepository();
  bool _isLoading = true;
  List<ProductModel> _products = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMyProducts();
  }

  Future<void> _loadMyProducts() async {
    final state = context.read<AuthBloc>().state;
    if (state is! Authenticated) {
      setState(() {
        _error = 'You must be logged in to view your listings';
        _isLoading = false;
      });
      return;
    }

    // Debug auth state
    debugPrint('Auth state type: ${state.runtimeType}');
    debugPrint('Current authenticated user ID: ${state.user.uid}');

    // Get more user info to verify
    final userData = await context.read<AuthBloc>().getUserData(state.user.uid);
    if (userData != null) {
      debugPrint(
        'User data retrieved - Name: ${userData.name}, Role: ${userData.role}',
      );
    } else {
      debugPrint('Could not retrieve user data for ID: ${state.user.uid}');
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('Requesting products for seller ID: ${state.user.uid}');
      final products = await _repository.getProductsBySeller(state.user.uid);
      debugPrint('Received ${products.length} products');

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error in _loadMyProducts: $e');
      setState(() {
        _error = 'Failed to load your products: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddProductBottomSheet(UserModel user) async {
    debugPrint('Opening bottom sheet with user ID: ${user.uid}');
    debugPrint('User name: ${user.name}, User role: ${user.role}');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AddProductBottomSheet(currentUser: user),
    );

    if (result == true) {
      // Refresh product list if a new product was added
      debugPrint('Product added, refreshing list...');
      _loadMyProducts();
    }
  }

  Future<void> _showEditProductBottomSheet(
    UserModel user,
    ProductModel product,
  ) async {
    debugPrint('Opening edit bottom sheet for product ID: ${product.id}');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) =>
              EditProductBottomSheet(currentUser: user, product: product),
    );

    if (result == true) {
      // Refresh product list if product was updated
      debugPrint('Product updated, refreshing list...');
      _loadMyProducts();
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Product'),
            content: const Text(
              'Are you sure you want to delete this product?',
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
        final success = await _repository.deleteProduct(productId);
        if (success) {
          _loadMyProducts();
        } else {
          setState(() {
            _isLoading = false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete product')),
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
      appBar: AppBar(title: const Text('My Listings')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : _products.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('You have no products listed yet'),
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
                                  _showAddProductBottomSheet(user);
                                }
                              });
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Product'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadMyProducts,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        leading: SizedBox(
                          width: 80,
                          height: 80,
                          child:
                              product.type == ProductType.video
                                  ? VideoThumbnailWidget(product: product)
                                  : (product.imageUrls != null &&
                                      product.imageUrls!.isNotEmpty)
                                  ? Image.network(
                                    product.imageUrls!.first,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: Center(
                                          child: Icon(
                                            product.type == ProductType.drone
                                                ? Icons.flight
                                                : Icons.image,
                                            size: 48,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                  : Container(
                                    color: Colors.grey.shade200,
                                    child: Center(
                                      child: Icon(
                                        product.type == ProductType.drone
                                            ? Icons.flight
                                            : Icons.image,
                                        size: 48,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                        ),
                        title: Text(
                          product.title!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'LKR ${product.price!.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.type
                                  .toString()
                                  .split('.')
                                  .last
                                  .toUpperCase(),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                final state = context.read<AuthBloc>().state;
                                if (state is Authenticated) {
                                  context
                                      .read<AuthBloc>()
                                      .getUserData(state.user.uid)
                                      .then((user) {
                                        if (user != null) {
                                          _showEditProductBottomSheet(
                                            user,
                                            product,
                                          );
                                        }
                                      });
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteProduct(product.id!),
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
            debugPrint(
              'Building FAB with authenticated user ID: ${state.user.uid}',
            );

            return FutureBuilder<UserModel?>(
              future: context.read<AuthBloc>().getUserData(state.user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  debugPrint('Getting user data...');
                  return const CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  debugPrint('Error getting user data: ${snapshot.error}');
                  return const SizedBox.shrink();
                }

                if (snapshot.hasData) {
                  final userData = snapshot.data!;
                  debugPrint(
                    'User data retrieved - ID: ${userData.uid}, Role: ${userData.role}',
                  );

                  if (userData.role == 'Pilot' ||
                      userData.role == 'Service Center') {
                    return FloatingActionButton(
                      onPressed: () => _showAddProductBottomSheet(userData),
                      child: const Icon(Icons.add),
                    );
                  }
                } else {
                  debugPrint(
                    'No user data retrieved for ID: ${state.user.uid}',
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

  IconData _getIconForProductType(ProductType type) {
    switch (type) {
      case ProductType.drone:
        return Icons.flight;
      case ProductType.image:
        return Icons.image;
      case ProductType.video:
        return Icons.videocam;
      default:
        return Icons.shopping_bag;
    }
  }
}
