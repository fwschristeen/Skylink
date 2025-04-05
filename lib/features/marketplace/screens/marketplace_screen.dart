import 'package:drone_user_app/features/auth/bloc/auth_bloc.dart';
import 'package:drone_user_app/features/auth/models/user_model.dart';
import 'package:drone_user_app/features/marketplace/models/product_model.dart';
import 'package:drone_user_app/features/marketplace/repositories/marketplace_repository.dart';
import 'package:drone_user_app/features/marketplace/widgets/add_product_bottom_sheet.dart';
import 'package:drone_user_app/features/marketplace/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  final MarketplaceRepository _repository = MarketplaceRepository();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  bool _isLoading = true;
  bool _isSearching = false;
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProducts();
    _searchController.addListener(_handleSearch);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_handleSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredProducts = _products;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });
    _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _repository.searchProducts(query);
      setState(() {
        _filteredProducts = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error searching products: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await _repository.getAllProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load products: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _filterByType(ProductType type) async {
    // If searching, don't apply tab filters
    if (_isSearching) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await _repository.getProductsByType(type);
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load products: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddProductBottomSheet(UserModel user) async {
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
      _loadProducts();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;

      // Restore tab filter
      final currentTab = _tabController.index;
      if (currentTab == 0) {
        _loadProducts();
      } else if (currentTab == 1) {
        _filterByType(ProductType.drone);
      } else if (currentTab == 2) {
        _filterByType(ProductType.image);
      } else if (currentTab == 3) {
        _filterByType(ProductType.video);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                onTap: (index) {
                  if (_isSearching) return; // Don't change tabs if searching

                  switch (index) {
                    case 0:
                      _loadProducts();
                      break;
                    case 1:
                      _filterByType(ProductType.drone);
                      break;
                    case 2:
                      _filterByType(ProductType.image);
                      break;
                    case 3:
                      _filterByType(ProductType.video);
                      break;
                  }
                },
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Drones'),
                  Tab(text: 'Images'),
                  Tab(text: 'Videos'),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1E1E1E)
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                      width: 1.0,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                      ),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                ),
                                onPressed: _clearSearch,
                              )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : _filteredProducts.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      _searchController.text.isEmpty
                          ? 'No products available'
                          : 'No results found for "${_searchController.text}"',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    if (_searchController.text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Clear search'),
                      ),
                    ],
                  ],
                ),
              )
              : GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.85,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: _filteredProducts[index],
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/product-details',
                        arguments: _filteredProducts[index],
                      );
                    },
                  );
                },
              ),
      floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return FutureBuilder<UserModel?>(
              future: context.read<AuthBloc>().getUserData(state.user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasData &&
                    (snapshot.data!.role == 'Pilot' ||
                        snapshot.data!.role == 'Service Center')) {
                  return FloatingActionButton(
                    onPressed: () => _showAddProductBottomSheet(snapshot.data!),
                    child: const Icon(Icons.add),
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
}
