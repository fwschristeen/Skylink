import 'package:drone_user_app/features/service_center/models/service_center_model.dart';
import 'package:drone_user_app/features/service_center/repositories/service_center_repository.dart';
import 'package:drone_user_app/features/service_center/widgets/service_center_card.dart';
import 'package:flutter/material.dart';

class ServiceCentersScreen extends StatefulWidget {
  const ServiceCentersScreen({super.key});

  @override
  State<ServiceCentersScreen> createState() => _ServiceCentersScreenState();
}

class _ServiceCentersScreenState extends State<ServiceCentersScreen> {
  final ServiceCenterRepository _repository = ServiceCenterRepository();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<ServiceCenterModel> _serviceCenters = [];
  List<ServiceCenterModel> _filteredServiceCenters = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadServiceCenters();
    _searchController.addListener(_handleSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _filteredServiceCenters = _serviceCenters;
      });
      return;
    }

    _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _repository.searchServiceCenters(query);
      setState(() {
        _filteredServiceCenters = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error searching service centers: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadServiceCenters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final serviceCenters = await _repository.getAllServiceCenters();
      setState(() {
        _serviceCenters = serviceCenters;
        _filteredServiceCenters = serviceCenters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load service centers: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Centers'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
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
                  hintText: 'Search by name, address, services...',
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
                            onPressed: () {
                              _searchController.clear();
                            },
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
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadServiceCenters,
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : _filteredServiceCenters.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'No service centers available'
                            : 'No results found for "${_searchController.text}"',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      if (_searchController.text.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () {
                            _searchController.clear();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Clear search'),
                        ),
                      ],
                    ],
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _filteredServiceCenters.length,
                  itemBuilder: (context, index) {
                    return ServiceCenterCard(
                      serviceCenter: _filteredServiceCenters[index],
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/service-center-details',
                          arguments: _filteredServiceCenters[index],
                        );
                      },
                    );
                  },
                ),
      ),
    );
  }
}
