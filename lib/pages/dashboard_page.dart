// ignore_for_file: deprecated_member_use, avoid_print, prefer_final_fields

import 'package:flutter/material.dart';
import '../models/asset_models.dart';
import '../services/asset_api_service.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DashboardPage({
    super.key,
    required this.userData,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<dynamic> _allSubAssets = [];
  List<dynamic> _filteredSubAssets = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedAssetName;
  Map<String, String> _subAssetToParentMap = {}; // Maps sub-asset to parent asset name
  
  List<String> get _assetNames {
    return _subAssetToParentMap.values.toSet().toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadAllSubAssets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterAndPageAssets();
  }

  Future<void> _loadAllSubAssets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<dynamic> allSubAssets = [];
      int currentPage = 1;
      bool hasMorePages = true;
      int? totalPages;
      
      print('Starting to load all sub-assets...');
      
      // Load all pages
      while (hasMorePages) {
        print('Fetching page $currentPage...');
        
        final AssetResponse response = await AssetApiService.fetchAssetsWithSubAssets(
          page: currentPage,
          limit: 10, // Match server's default limit
        );
        
        print('Page $currentPage: Received ${response.assets.length} main assets');
        
        // Extract all sub-assets from this page and track parent asset names
        int subAssetsInPage = 0;
        for (var asset in response.assets) {
          if (asset.subAssets?.immovable != null) {
            final subAssets = asset.subAssets!.immovable!;
            final parentAssetName = asset.assetName ?? 'Unknown';
            
            for (var subAsset in subAssets) {
              allSubAssets.add(subAsset);
              // Map sub-asset ID to parent asset name
              final subAssetId = subAsset.id?.toString() ?? 
                                 subAsset.tagId?.toString() ?? 
                                 'unknown';
              _subAssetToParentMap[subAssetId] = parentAssetName;
            }
            subAssetsInPage += subAssets.length;
          }
        }
        
        print('Page $currentPage: Extracted $subAssetsInPage sub-assets');
        print('Total sub-assets so far: ${allSubAssets.length}');
        print('Unique asset names: ${_subAssetToParentMap.values.toSet().length}');
        
        // Check if there are more pages
        if (response.pagination != null) {
          totalPages = response.pagination!.pages;
          print('Pagination info - Current page: ${response.pagination!.page}, Total pages: $totalPages, Total assets: ${response.pagination!.total}');
          hasMorePages = currentPage < totalPages;
          
          print('Will fetch more pages? hasMorePages = $hasMorePages, currentPage = $currentPage, totalPages = $totalPages');
        } else {
          print('No pagination info available');
          hasMorePages = false;
        }
        
        // Increment page counter BEFORE next iteration
        currentPage++;
        print('Incremented currentPage to: $currentPage');
        
        // Safety check to prevent infinite loop
        if (currentPage > 10) {
          print('Safety limit reached. Stopping pagination.');
          hasMorePages = false;
        }
      }
      
      print('Completed loading. Total sub-assets: ${allSubAssets.length}');
      
      setState(() {
        _allSubAssets = allSubAssets;
        _isLoading = false;
      });
      
      _filterAndPageAssets();
    } catch (e) {
      print('Error loading sub-assets: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterAndPageAssets() {
    List<dynamic> filtered = _allSubAssets;
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchQuery = _searchController.text.toLowerCase();
      filtered = filtered.where((subAsset) {
        final name = subAsset.displayName?.toString().toLowerCase() ?? '';
        final id = subAsset.displayId?.toString().toLowerCase() ?? '';
        final status = subAsset.displayStatus?.toString().toLowerCase() ?? '';
        final category = subAsset.category?.toString().toLowerCase() ?? '';
        final brand = subAsset.brand?.toString().toLowerCase() ?? '';
        
        return name.contains(searchQuery) ||
            id.contains(searchQuery) ||
            status.contains(searchQuery) ||
            category.contains(searchQuery) ||
            brand.contains(searchQuery);
      }).toList();
    }
    
    // Apply asset name filter
    if (_selectedAssetName != null && _selectedAssetName!.isNotEmpty) {
      filtered = filtered.where((subAsset) {
        final subAssetId = subAsset.id?.toString() ?? 
                           subAsset.tagId?.toString() ?? 
                           'unknown';
        final parentAssetName = _subAssetToParentMap[subAssetId] ?? '';
        return parentAssetName == _selectedAssetName;
      }).toList();
    }
    
    setState(() {
      _filteredSubAssets = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF00BFFF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Asset Management',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Manage and track your assets',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search and Filter Section in Single Row
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 14,
                          ),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.search_rounded,
                              color: Color(0xFF00BFFF),
                              size: 20,
                            ),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButton<String?>(
                        value: _selectedAssetName,
                        isExpanded: true,
                        isDense: false,
                        underline: Container(),
                        menuMaxHeight: 200,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'All Assets',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                        icon: const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Color(0xFF00BFFF),
                            size: 24,
                          ),
                        ),
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('All Assets'),
                            ),
                          ),
                          ..._assetNames.map((String name) {
                            return DropdownMenuItem<String?>(
                              value: name,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedAssetName = newValue;
                          });
                          _filterAndPageAssets();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sub-Assets Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFFF)),
                      ),
                    )
                  : _filteredSubAssets.isEmpty
                      ? _buildEmptySubAssets()
                      : RefreshIndicator(
                          onRefresh: _loadAllSubAssets,
                          color: const Color(0xFF00BFFF),
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: _filteredSubAssets.length,
                            itemBuilder: (context, index) {
                              return _buildSubAssetCard(_filteredSubAssets[index]);
                            },
                          ),
                        ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildSubAssetCard(dynamic subAsset) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and status
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: subAsset.statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: subAsset.statusColor.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subAsset.displayName ?? 'Unknown Sub-Asset',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subAsset.displayId ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: subAsset.statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    subAsset.displayStatus ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: subAsset.statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            
            // Details Grid
            ..._buildDetailItems(subAsset),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDetailItems(dynamic subAsset) {
    List<Widget> items = [];
    
    final category = subAsset.category?.toString() ?? '';
    if (_isValidField(category)) {
      items.add(_buildDetailItem('Category', category, Icons.category_rounded));
      items.add(const SizedBox(height: 10));
    }
    
    final brand = subAsset.brand?.toString() ?? '';
    if (_isValidField(brand)) {
      items.add(_buildDetailItem('Brand', brand, Icons.business_rounded));
      items.add(const SizedBox(height: 10));
    }
    
    final model = subAsset.model?.toString() ?? '';
    if (_isValidField(model)) {
      items.add(_buildDetailItem('Model', model, Icons.build_rounded));
      items.add(const SizedBox(height: 10));
    }
    
    final priority = subAsset.priority?.toString() ?? '';
    if (_isValidField(priority)) {
      items.add(_buildDetailItem('Priority', priority, Icons.priority_high_rounded));
      items.add(const SizedBox(height: 10));
    }
    
    final capacity = subAsset.capacity?.toString() ?? '';
    if (_isValidField(capacity)) {
      items.add(_buildDetailItem('Capacity', capacity, Icons.straighten_rounded));
      items.add(const SizedBox(height: 10));
    }
    
    if (items.isNotEmpty) {
      items.removeLast(); // Remove last SizedBox
    }
    
    return items;
  }

  bool _isValidField(String? value) {
    if (value == null || value.isEmpty) return false;
    final lowerValue = value.toLowerCase().trim();
    return lowerValue != 'na' && 
           lowerValue != 'n/a' && 
           lowerValue != 'null' && 
           lowerValue != 'none' &&
           lowerValue != 'undefined';
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF00BFFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF00BFFF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySubAssets() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F8FF),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: const Color(0xFF00BFFF).withOpacity(0.2),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.extension_outlined,
              color: Color(0xFF00BFFF),
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _filteredSubAssets.isEmpty && _searchController.text.isNotEmpty
                ? 'No Results Found'
                : 'No Sub-Assets Found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filteredSubAssets.isEmpty && _searchController.text.isNotEmpty
                ? 'Try different search terms'
                : 'Sub-assets from main assets will appear here',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

}

