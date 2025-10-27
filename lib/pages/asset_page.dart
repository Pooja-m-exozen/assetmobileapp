// ignore_for_file: deprecated_member_use

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
  List<Asset> _assets = [];
  List<Asset> _filteredAssets = [];
  bool _isLoading = true;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final AssetResponse response = await AssetApiService.fetchAssetsWithSubAssets();
      setState(() {
        _assets = response.assets;
        _filteredAssets = _assets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterAssets() {
    setState(() {
      _filteredAssets = _assets.where((asset) {
        final matchesSearch = _searchQuery.isEmpty ||
            asset.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            asset.displayId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            asset.displayCategory.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            asset.displayBrand.toLowerCase().contains(_searchQuery.toLowerCase());
        
        return matchesSearch;
      }).toList();
    });
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF00BFFF),
                    Color(0xFF87CEEB),
                  ],
                ),
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
                                widget.isViewerMode ? 'Asset Viewer' : 'Asset Management',
                                style: const TextStyle(
                                  fontSize: 22,
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
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.isViewerMode ? Icons.visibility : Icons.inventory_2,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Enhanced Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    // Enhanced Search (for viewer mode only)
                    if (widget.isViewerMode) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                            _filterAssets();
                          },
                          decoration: InputDecoration(
                            hintText: 'Search assets...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(12),
                              child: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF00BFFF),
                                size: 22,
                              ),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                      _filterAssets();
                                    },
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      color: Color(0xFF999999),
                                      size: 20,
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    
                    const SizedBox(height: 20),
                    
                    // Content based on state
                    Expanded(
                      child: _isLoading
                          ? _buildLoadingState()
                          : _errorMessage != null
                              ? _buildErrorState()
                              : _filteredAssets.isEmpty
                                  ? _buildEmptyState()
                                  : RefreshIndicator(
                                      onRefresh: _loadAssets,
                                      color: const Color(0xFF00BFFF),
                                      child: ListView.builder(
                                        controller: _scrollController,
                                        physics: const AlwaysScrollableScrollPhysics(),
                                      itemCount: _filteredAssets.length,
                                      itemBuilder: (context, index) {
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
                
                // Compact Sub-assets Indicator
                  if (asset.subAssets?.immovable?.isNotEmpty == true) ...[
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
                            '${asset.subAssets!.immovable!.length} Sub-assets',
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
              Icons.inventory_2_outlined,
              color: Color(0xFF00BFFF),
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Assets Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or check your connection',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 20),
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
                  
                  // Sub-assets Section
                  if (asset.subAssets?.immovable?.isNotEmpty == true) ...[
                    const SizedBox(height: 24),
                    _buildModalSection(
                      context,
                      'Sub-Assets',
                      Icons.subdirectory_arrow_right_rounded,
                      asset.subAssets!.immovable!.map((subAsset) => 
                        _buildSubAssetCard(context, subAsset)
                      ).toList(),
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
        gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF00BFFF),
                      Color(0xFF87CEEB),
                    ],
                  ),
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
          _showComingSoonModal(context, label, icon, color);
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
    String location = subAsset.displayLocation ?? '';
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
                  color: subAsset.statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subAsset.displayName,
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
            '${subAsset.displayId} • $location',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subAsset.displayStatus,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: subAsset.statusColor,
            ),
          ),
        ],
      ),
    );
  }
}