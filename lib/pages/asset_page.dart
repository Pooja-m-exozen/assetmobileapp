// ignore_for_file: deprecated_member_use, avoid_print, unnecessary_to_list_in_spreads

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/asset_models.dart';
import '../services/asset_api_service.dart';

class AssetPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isViewerMode;
  
  const AssetPage({
    super.key,
    required this.userData,
    this.isViewerMode = false,
  });

  @override
  State<AssetPage> createState() => _AssetPageState();
}

class _AssetPageState extends State<AssetPage> {
  String _searchQuery = '';
  List<Asset> _allAssets = [];
  List<Asset> _filteredAssets = [];
  bool _isLoading = true;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedAssetName;
  
  List<String> get _assetNames {
    return _allAssets.map((asset) => asset.displayName).toSet().toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Asset> allAssets = [];
      int currentPage = 1;
      bool hasMorePages = true;
      int? totalPages;
      
      print('Loading all assets from asset_page...');
      
      // Load all pages
      while (hasMorePages) {
        print('Fetching page $currentPage...');
        
        final AssetResponse response = await AssetApiService.fetchAssetsWithSubAssets(
          page: currentPage,
          limit: 10,
        );
        
        print('Page $currentPage: Received ${response.assets.length} assets');
        allAssets.addAll(response.assets);
        
        // Check if there are more pages
        if (response.pagination != null) {
          totalPages = response.pagination!.pages;
          print('Pagination - Page: ${response.pagination!.page}, Total pages: $totalPages, Total assets: ${response.pagination!.total}');
          hasMorePages = currentPage < totalPages;
        } else {
          print('No pagination info available');
          hasMorePages = false;
        }
        
        currentPage++;
        
        // Safety check
        if (currentPage > 10) {
          print('Safety limit reached. Stopping pagination.');
          hasMorePages = false;
        }
      }
      
      print('Completed loading all assets. Total: ${allAssets.length}');
      
      // Filter assets by user's project name
      String? userProjectName = widget.userData['projectName']?.toString();
      List<Asset> filteredByProject = [];
      
      if (userProjectName != null && userProjectName.isNotEmpty) {
        print('Filtering assets for project: $userProjectName');
        filteredByProject = allAssets.where((asset) {
          bool matches = asset.project?.projectName == userProjectName;
          if (!matches) {
            print('Asset ${asset.displayName} excluded - Project: ${asset.project?.projectName}');
          }
          return matches;
        }).toList();
        print('Filtered to ${filteredByProject.length} assets matching project: $userProjectName');
      } else {
        print('No project name specified in user data, showing all assets');
        filteredByProject = allAssets;
      }
      
      setState(() {
        _allAssets = filteredByProject;
        _filteredAssets = filteredByProject;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading assets: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterAssets() {
    List<Asset> filtered = _allAssets;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((asset) {
        return asset.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            asset.displayId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            asset.displayCategory.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            asset.displayBrand.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply asset name filter
    if (_selectedAssetName != null && _selectedAssetName!.isNotEmpty) {
      filtered = filtered.where((asset) {
        return asset.displayName == _selectedAssetName;
      }).toList();
    }
    
    setState(() {
      _filteredAssets = filtered;
    });
  }

  int _getTotalSubAssets() {
    int total = 0;
    for (var asset in _allAssets) {
      final immovableCount = asset.subAssets?.immovable?.length ?? 0;
      final movableCount = asset.subAssets?.movable?.length ?? 0;
      total += immovableCount + movableCount;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Standard App Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: Color(0xFF00BFFF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${widget.userData['name']?.toString().toUpperCase() ?? 'USER'}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.isViewerMode ? 'View and browse assets' : 'Manage and track your assets',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.white,
                              child: Text(
                                widget.userData['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00BFFF),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                // Navigate back to login page
                                Navigator.of(context).pushReplacementNamed('/');
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.logout,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Scrollable Content (everything below header)
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAssets,
                color: const Color(0xFF00BFFF),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Column(
                          children: [
                            // Search and Filter in Single Row
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(28),
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
                                      onChanged: (value) {
                                        _searchQuery = value;
                                        _filterAssets();
                                      },
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
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() {
                                                    _searchQuery = '';
                                                  });
                                                  _filterAssets();
                                                },
                                                icon: const Icon(
                                                  Icons.clear_rounded,
                                                  color: Color(0xFF999999),
                                                  size: 18,
                                                ),
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
                                      menuMaxHeight: 200, // Limit visible items to ~4
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
                                          size: 16,
                                        ),
                                      ),
                                      dropdownColor: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
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
                                        _filterAssets();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Asset Count Cards
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00BFFF),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00BFFF).withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(
                                            Icons.inventory_2_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total Assets',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white.withOpacity(0.9),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_allAssets.length}',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFC107),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFFC107).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(
                                            Icons.subdirectory_arrow_right_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total Sub-assets',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white.withOpacity(0.95),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_getTotalSubAssets()}',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Content based on state
                    _isLoading
                        ? SliverFillRemaining(child: _buildLoadingState())
                        : _errorMessage != null
                            ? SliverFillRemaining(child: _buildErrorState())
                            : _filteredAssets.isEmpty
                                ? SliverFillRemaining(child: _buildEmptyState())
                                : SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final asset = _filteredAssets[index];
                                          return TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 0.0, end: 1.0),
                                            duration: Duration(milliseconds: 300 + (index * 50)),
                                            curve: Curves.easeOut,
                                            builder: (context, value, child) {
                                              return Opacity(
                                                opacity: value,
                                                child: Transform.translate(
                                                  offset: Offset(0, 20 * (1 - value)),
                                                  child: child,
                                                ),
                                              );
                                            },
                                            child: _buildAssetItem(asset),
                                          );
                                        },
                                        childCount: _filteredAssets.length,
                                      ),
                                    ),
                                  ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetItem(Asset asset) {
    return GestureDetector(
      onTap: () => _showAssetDetails(asset),
      child: Material(
        color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
          child: Padding(
            padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                // Asset Name and Status
                Row(
                children: [
                  Expanded(
                    child: Text(
                        asset.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                        fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                      ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                    ),
                  ),
                    // Simplified status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: asset.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: asset.statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            asset.displayStatus,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: asset.statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                ),
                
                const SizedBox(height: 8),
                
                // Asset ID
                        Row(
                          children: [
                    const Icon(
                                Icons.tag_rounded,
                      size: 14,
                      color: Color(0xFF999999),
                              ),
                    const SizedBox(width: 4),
                            Expanded(
                      child: Text(
                        asset.displayId,
                        style: const TextStyle(
                          fontSize: 13,
                                      color: Color(0xFF666666),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                    ),
                    if (asset.hasDigitalAssets == true)
                            Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                          Icons.qr_code_2_rounded,
                          size: 14,
                                color: Color(0xFF4CAF50),
                              ),
                      ),
                  ],
                ),
                  
                const SizedBox(height: 12),
                
                  // Asset Details Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (asset.displayCategory.isNotEmpty && asset.displayCategory != 'NA' && asset.displayCategory != 'N/A')
                        _buildModernChip(asset.displayCategory, Icons.category_rounded, const Color(0xFF9C27B0)),
                      if (asset.displayBrand.isNotEmpty && asset.displayBrand != 'NA' && asset.displayBrand != 'N/A')
                        _buildModernChip(asset.displayBrand, Icons.business_rounded, const Color(0xFF2196F3)),
                      if (asset.displayModel.isNotEmpty && asset.displayModel != 'N/A' && asset.displayModel != 'NA')
                        _buildModernChip(asset.displayModel, Icons.build_rounded, const Color(0xFFFF9800)),
                    ],
                  ),
                
                  // Compact Sub-assets Indicator (movable + immovable)
                  if (((asset.subAssets?.immovable?.length ?? 0) + (asset.subAssets?.movable?.length ?? 0)) > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                        children: [
                      Icon(
                              Icons.subdirectory_arrow_right_rounded,
                        size: 16,
                        color: const Color(0xFF00BFFF),
                            ),
                      const SizedBox(width: 6),
                          Text(
                            '${(asset.subAssets?.immovable?.length ?? 0) + (asset.subAssets?.movable?.length ?? 0)} Sub-assets',
                            style: const TextStyle(
                          fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00BFFF),
                            ),
                          ),
                        ],
                    ),
                  ],
                ],
              ),
            ),
        ),
      ),
    );
  }

  void _showAssetDetails(Asset asset) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: _AssetDetailsDialog(asset: asset),
      ),
    );
  }


  // Simplified chip widget
  Widget _buildModernChip(String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFFF)),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading assets...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load assets',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadAssets,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFFF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasActiveFilters = _searchQuery.isNotEmpty || _selectedAssetName != null;
    
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
            child: Icon(
              hasActiveFilters ? Icons.filter_alt_outlined : Icons.inventory_2_outlined,
              color: const Color(0xFF00BFFF),
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hasActiveFilters ? 'No Matching Assets' : 'No Assets Found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasActiveFilters 
                ? 'Try adjusting your search or filter settings'
                : 'Check your connection or try again',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 20),
          if (hasActiveFilters)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedAssetName = null;
                  _searchController.clear();
                });
                _filterAssets();
              },
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _loadAssets,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Dialog for asset details
class _AssetDetailsDialog extends StatelessWidget {
  final Asset asset;

  const _AssetDetailsDialog({required this.asset});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // Header
          _buildHeader(context),
          
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  _buildStatusBadge(context),
                  const SizedBox(height: 24),
                  
                  // Basic Information Section
                  _buildModalSection(
                    context,
                    'Basic Information',
                    Icons.info_outline_rounded,
                    [
                        _buildDetailRow(context, 'Asset ID', asset.displayId, Icons.tag_rounded),
                        _buildDetailRow(context, 'Type', asset.displayCategory, Icons.category_rounded),
                        _buildDetailRow(context, 'Brand', asset.displayBrand, Icons.business_rounded),
                        if (asset.displayModel.isNotEmpty && asset.displayModel != 'N/A' && asset.displayModel != 'NA')
                          _buildDetailRow(context, 'Model', asset.displayModel, Icons.build_rounded),
                        if (asset.capacity?.isNotEmpty == true && asset.capacity != 'NA' && asset.capacity != 'N/A')
                          _buildDetailRow(context, 'Capacity', asset.capacity!, Icons.straighten_rounded),
                        if (asset.priority != null && asset.priority!.isNotEmpty && asset.priority != 'NA' && asset.priority != 'N/A')
                          _buildDetailRow(context, 'Priority', asset.priority!, Icons.priority_high_rounded),
                        if (asset.description?.isNotEmpty == true)
                          _buildDetailRow(context, 'Description', asset.description!, Icons.description_rounded),
                    ],
                  ),
                  
                  // Sub-assets Section (show both immovable and movable)
                  if ((asset.subAssets?.immovable?.isNotEmpty == true) || (asset.subAssets?.movable?.isNotEmpty == true)) ...[
                    const SizedBox(height: 24),
                    _buildModalSection(
                      context,
                      'Sub-Assets',
                      Icons.subdirectory_arrow_right_rounded,
                      [
                        ...(asset.subAssets?.immovable ?? []).map((subAsset) =>
                          _buildSubAssetCard(context, subAsset)
                        ).toList(),
                        ...(asset.subAssets?.movable ?? []).map((subAsset) =>
                          _buildSubAssetCard(context, subAsset)
                        ).toList(),
                      ],
                    ),
                  ],
                  
                  // Action Buttons
                  const SizedBox(height: 24),
                  _buildActionButtons(context),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF00BFFF),
        borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Asset Details',
                            style: TextStyle(
                    fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                const SizedBox(height: 6),
                          Text(
                            asset.displayName,
                            style: const TextStyle(
                    fontSize: 15,
                              color: Colors.white70,
                    fontWeight: FontWeight.w500,
                            ),
                  maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
          const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
              padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
                    children: [
        Expanded(
          child: _buildActionButton(
            context,
            'PO',
            Icons.description_rounded,
            const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            context,
            'LifeCycle',
            Icons.timeline_rounded,
            const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            context,
            'Replace',
            Icons.swap_horiz_rounded,
            const Color(0xFFFF9800),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (label == 'LifeCycle') {
            _showLifecycleDialog(context);
          } else {
            _showComingSoonModal(context, label, icon, color);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
                          border: Border.all(
              color: color.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
          child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
                            Text(
                label,
                              style: TextStyle(
                                fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  void _showComingSoonModal(BuildContext context, String feature, IconData icon, Color color) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                feature,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This feature is under development and will be available soon.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                      foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                    'Got it',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: asset.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: asset.statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: asset.statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            asset.displayStatus.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: asset.statusColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildModalSection(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE9ECEF),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00BFFF).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF00BFFF),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE9ECEF),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00BFFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
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
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubAssetCard(BuildContext context, dynamic subAsset) {
    // Support both model objects and raw Map sub-asset items
    final bool isMap = subAsset is Map;
    final String name = isMap
        ? (subAsset['displayName']?.toString() ?? subAsset['assetName']?.toString() ?? subAsset['name']?.toString() ?? '')
        : (subAsset.displayName ?? '');
    final String id = isMap
        ? (subAsset['displayId']?.toString() ?? subAsset['tagId']?.toString() ?? subAsset['id']?.toString() ?? '')
        : (subAsset.displayId ?? '');
    final String status = isMap
        ? (subAsset['displayStatus']?.toString() ?? subAsset['status']?.toString() ?? '')
        : (subAsset.displayStatus ?? '');

    Color statusColor;
    if (!isMap) {
      statusColor = subAsset.statusColor;
    } else {
      final dynamic provided = subAsset['statusColor'];
      if (provided is int) {
        statusColor = Color(provided);
      } else if (provided is String) {
        final String hex = provided.replaceAll('#', '');
        try {
          statusColor = Color(int.parse('FF$hex', radix: 16));
        } catch (_) {
          statusColor = _statusFallbackColor(status);
        }
      } else {
        statusColor = _statusFallbackColor(status);
      }
    }

    String location = isMap
        ? (subAsset['displayLocation']?.toString() ?? subAsset['location']?.toString() ?? '')
        : (subAsset.displayLocation ?? '');
    if (location.contains('{') || location.contains('}') || location.contains('null')) {
      location = location
          .replaceAll(RegExp(r'[{}]'), '')
          .replaceAll('null', '')
          .replaceAll(',', '')
          .replaceAll('floor:', '')
          .replaceAll('room:', '')
          .replaceAll('building:', '')
          .trim();
      if (location.isEmpty) {
        return Container();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE9ECEF),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$id • $location',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _statusFallbackColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('active') || s.contains('working') || s.contains('ok')) {
      return const Color(0xFF4CAF50);
    }
    if (s.contains('fault') || s.contains('down') || s.contains('error') || s.contains('repair')) {
      return const Color(0xFFF44336);
    }
    if (s.contains('inactive') || s.contains('idle')) {
      return const Color(0xFF9E9E9E);
    }
    return const Color(0xFF00BFFF);
  }

  void _showLifecycleDialog(BuildContext context) {
    final lifecycle = asset.financial?.lifecycle;
    final replacementHistory = asset.financial?.replacementHistory ?? asset.replacementHistory ?? [];
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Asset Lifecycle',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            asset.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lifecycle Status
                      if (lifecycle != null && lifecycle.status != null) ...[
                        _buildLifecycleSection(
                          'Lifecycle Status',
                          Icons.timeline_rounded,
                          [
                            _buildLifecycleStatusCard(
                              lifecycle.status!,
                              _getLifecycleStatusColor(lifecycle.status!),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Asset Timeline
                      _buildLifecycleSection(
                        'Asset Timeline',
                        Icons.history_rounded,
                        [
                          _buildTimelineItem(
                            'Asset Created',
                            asset.createdAt ?? 'Unknown',
                            Icons.add_circle_outline,
                            const Color(0xFF00BFFF),
                            true,
                          ),
                          if (asset.updatedAt != null)
                            _buildTimelineItem(
                              'Last Updated',
                              asset.updatedAt!,
                              Icons.update_rounded,
                              const Color(0xFFFFC107),
                              false,
                            ),
                        ],
                      ),

                      // Lifecycle Stages
                      const SizedBox(height: 24),
                      _buildLifecycleStagesSection(lifecycle?.status, asset.createdAt, asset.updatedAt),

                      // Replacement History - Detailed
                      if (replacementHistory.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildLifecycleSection(
                          'Replacement History',
                          Icons.swap_horiz_rounded,
                          replacementHistory.asMap().entries.map((entry) {
                            final index = entry.key;
                            final replacement = entry.value;
                            return _buildReplacementCard(replacement, index + 1);
                          }).toList(),
                        ),
                      ] else ...[
                        const SizedBox(height: 24),
                        _buildLifecycleSection(
                          'Replacement History',
                          Icons.swap_horiz_rounded,
                          [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE9ECEF),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: Colors.grey[400],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'No replacement history available for this asset',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Additional Lifecycle Information
                      const SizedBox(height: 24),
                      _buildLifecycleSection(
                        'Lifecycle Details',
                        Icons.info_outline_rounded,
                        [
                          _buildLifecycleDetailRow(
                            'Asset ID',
                            asset.displayId,
                            Icons.tag_rounded,
                          ),
                          if (asset.status != null)
                            _buildLifecycleDetailRow(
                              'Current Status',
                              asset.displayStatus,
                              Icons.info_outline_rounded,
                            ),
                          if (lifecycle?.status != null && lifecycle!.status!.isNotEmpty)
                            _buildLifecycleDetailRow(
                              'Lifecycle Status',
                              lifecycle.status!,
                              Icons.timeline_rounded,
                            ),
                          if (asset.displayCategory.isNotEmpty && asset.displayCategory != 'N/A')
                            _buildLifecycleDetailRow(
                              'Category',
                              asset.displayCategory,
                              Icons.category_rounded,
                            ),
                          if (asset.displayBrand.isNotEmpty && asset.displayBrand != 'N/A' && asset.displayBrand != 'NA')
                            _buildLifecycleDetailRow(
                              'Brand',
                              asset.displayBrand,
                              Icons.business_rounded,
                            ),
                          if (asset.location != null && 
                              (asset.location!.building != null || asset.location!.floor != null || asset.location!.room != null))
                            _buildLifecycleDetailRow(
                              'Location',
                              _formatLocation(asset.location!),
                              Icons.location_on_rounded,
                            ),
                          if (asset.financial?.purchaseOrder?.currency != null)
                            _buildLifecycleDetailRow(
                              'Currency',
                              asset.financial!.purchaseOrder!.currency!,
                              Icons.attach_money_rounded,
                            ),
                          if (asset.createdAt != null)
                            _buildLifecycleDetailRow(
                              'Created Date',
                              _formatDate(asset.createdAt),
                              Icons.calendar_today_rounded,
                            ),
                          if (asset.updatedAt != null)
                            _buildLifecycleDetailRow(
                              'Last Updated',
                              _formatDate(asset.updatedAt),
                              Icons.update_rounded,
                            ),
                          if ((asset.financial?.replacementHistory?.length ?? 0) > 0)
                            _buildLifecycleDetailRow(
                              'Total Replacements',
                              '${asset.financial!.replacementHistory!.length}',
                              Icons.swap_horiz_rounded,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLifecycleSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE9ECEF),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleStatusCard(String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getLifecycleStatusIcon(status),
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String date, IconData icon, Color color, bool isFirst) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              if (!isFirst)
                Container(
                  width: 2,
                  height: 20,
                  color: Colors.grey[300],
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleDetailRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF00BFFF),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLocation(Location location) {
    List<String> parts = [];
    if (location.building != null && location.building!.isNotEmpty) {
      parts.add('Bldg: ${location.building}');
    }
    if (location.floor != null && location.floor!.isNotEmpty) {
      parts.add('Floor: ${location.floor}');
    }
    if (location.room != null && location.room!.isNotEmpty) {
      parts.add('Room: ${location.room}');
    }
    return parts.isEmpty ? 'Location not specified' : parts.join(', ');
  }

  Color _getLifecycleStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('active') || s.contains('operational') || s.contains('in-use')) {
      return const Color(0xFF4CAF50);
    }
    if (s.contains('procured') || s.contains('purchased') || s.contains('acquired')) {
      return const Color(0xFF2196F3);
    }
    if (s.contains('maintenance') || s.contains('repair') || s.contains('service')) {
      return const Color(0xFFFF9800);
    }
    if (s.contains('retired') || s.contains('decommissioned') || s.contains('disposed')) {
      return const Color(0xFFF44336);
    }
    if (s.contains('deprecated') || s.contains('obsolete')) {
      return const Color(0xFF9E9E9E);
    }
    return const Color(0xFF4CAF50);
  }

  IconData _getLifecycleStatusIcon(String status) {
    final s = status.toLowerCase();
    if (s.contains('active') || s.contains('operational') || s.contains('in-use')) {
      return Icons.check_circle_rounded;
    }
    if (s.contains('procured') || s.contains('purchased') || s.contains('acquired')) {
      return Icons.shopping_cart_rounded;
    }
    if (s.contains('maintenance') || s.contains('repair') || s.contains('service')) {
      return Icons.build_rounded;
    }
    if (s.contains('retired') || s.contains('decommissioned') || s.contains('disposed')) {
      return Icons.delete_outline_rounded;
    }
    if (s.contains('deprecated') || s.contains('obsolete')) {
      return Icons.warning_rounded;
    }
    return Icons.timeline_rounded;
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == 'Unknown') {
      return 'Date not available';
    }
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildLifecycleStagesSection(String? lifecycleStatus, String? createdAt, String? updatedAt) {
    final status = lifecycleStatus?.toLowerCase() ?? asset.status?.toLowerCase() ?? '';
    final replacementHistory = asset.financial?.replacementHistory ?? asset.replacementHistory ?? [];
    final hasBeenReplaced = replacementHistory.isNotEmpty || status.contains('replaced') || status.contains('replacement');
    
    return _buildLifecycleSection(
      'Lifecycle Stages',
      Icons.track_changes_rounded,
      [
        // Procured Stage
        _buildSimpleLifecycleStage(
          'Procured',
          'Asset procurement date',
          createdAt ?? 'Unknown',
          Icons.shopping_cart_rounded,
          const Color(0xFF2196F3),
          true,
        ),
        
        // Active/Deployed Stage
        if (asset.status != null && (asset.status!.toLowerCase().contains('active') || asset.status!.toLowerCase().contains('procured')))
          _buildSimpleLifecycleStage(
            'Active',
            'Asset is currently active and operational',
            updatedAt ?? createdAt ?? 'Unknown',
            Icons.check_circle_rounded,
            const Color(0xFF4CAF50),
            status.contains('active') || asset.status!.toLowerCase().contains('active'),
          ),
        
        // Maintenance Stage (if applicable)
        if (status.contains('maintenance') || asset.status?.toLowerCase().contains('maintenance') == true)
          _buildSimpleLifecycleStage(
            'Maintenance',
            'Asset under maintenance or repair',
            updatedAt ?? 'Unknown',
            Icons.build_rounded,
            const Color(0xFFFF9800),
            false,
          ),
        
        // Replaced Stage (if replaced)
        if (hasBeenReplaced)
          _buildSimpleLifecycleStage(
            'Replaced',
            replacementHistory.isNotEmpty 
                ? 'Asset was replaced ${replacementHistory.length} time(s)'
                : 'Asset has been replaced',
            replacementHistory.isNotEmpty && replacementHistory[0] is Map
                ? (replacementHistory[0] as Map)['date']?.toString() ?? 
                  (replacementHistory[0] as Map)['replacedAt']?.toString() ?? 
                  updatedAt ?? 'Unknown'
                : updatedAt ?? 'Unknown',
            Icons.swap_horiz_rounded,
            const Color(0xFFFF9800),
            false,
          ),
        
        // Retired Stage (if applicable)
        if (status.contains('retired') || status.contains('decommissioned') || status.contains('disposed') || 
            asset.status?.toLowerCase().contains('retired') == true)
          _buildSimpleLifecycleStage(
            'Retired',
            'Asset has been retired or decommissioned',
            updatedAt ?? 'Unknown',
            Icons.delete_outline_rounded,
            const Color(0xFFF44336),
            false,
          ),
      ],
    );
  }

  Widget _buildSimpleLifecycleStage(
    String title,
    String description,
    String date,
    IconData icon,
    Color color,
    bool isCurrent,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCurrent ? color.withOpacity(0.15) : Colors.grey[100],
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrent ? color : Colors.grey[300]!,
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
              color: isCurrent ? color : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isCurrent ? color : const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplacementCard(dynamic replacement, int replacementNumber) {
    // Parse replacement data
    String replacementTitle = 'Replacement #$replacementNumber';
    String replacementDate = 'Date not available';
    String replacementReason = 'No reason specified';
    String replacedAssetId = '';
    String replacementAssetId = '';
    
    if (replacement is Map) {
      replacementTitle = replacement['title']?.toString() ?? 
                         replacement['replacementNumber']?.toString() ?? 
                         'Replacement #$replacementNumber';
      replacementDate = replacement['date']?.toString() ?? 
                       replacement['replacedAt']?.toString() ?? 
                       replacement['replacementDate']?.toString() ?? 
                       replacement['createdAt']?.toString() ?? 
                       'Date not available';
      replacementReason = replacement['reason']?.toString() ?? 
                         replacement['description']?.toString() ?? 
                         replacement['notes']?.toString() ?? 
                         'No reason specified';
      replacedAssetId = replacement['replacedAssetId']?.toString() ?? 
                       replacement['oldAssetId']?.toString() ?? 
                       '';
      replacementAssetId = replacement['replacementAssetId']?.toString() ?? 
                          replacement['newAssetId']?.toString() ?? 
                          '';
    } else if (replacement is String) {
      replacementDate = replacement;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE9ECEF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: Color(0xFFFF9800),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      replacementTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(replacementDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Reason for Replacement',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  replacementReason,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (replacedAssetId.isNotEmpty || replacementAssetId.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (replacedAssetId.isNotEmpty) ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF44336).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFF44336).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.remove_circle_outline,
                                size: 14,
                                color: Color(0xFFF44336),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Replaced Asset',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF666666),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            replacedAssetId,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (replacedAssetId.isNotEmpty && replacementAssetId.isNotEmpty)
                  const SizedBox(width: 8),
                if (replacementAssetId.isNotEmpty) ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.add_circle_outline,
                                size: 14,
                                color: Color(0xFF4CAF50),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Replacement Asset',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF666666),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            replacementAssetId,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}