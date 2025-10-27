// ignore_for_file: deprecated_member_use

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllSubAssets();
  }

  Future<void> _loadAllSubAssets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final AssetResponse response = await AssetApiService.fetchAssetsWithSubAssets();
      
      // Extract all sub-assets from all main assets
      List<dynamic> allSubAssets = [];
      for (var asset in response.assets) {
        if (asset.subAssets?.immovable != null) {
          allSubAssets.addAll(asset.subAssets!.immovable!);
        }
      }
      
      setState(() {
        _allSubAssets = allSubAssets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF00BFFF),
                    Color(0xFF87CEEB),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Welcome, ${widget.userData['name']?.toString().toUpperCase() ?? 'USER'}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
                               padding: const EdgeInsets.all(8),
                               decoration: BoxDecoration(
                                 color: Colors.white.withOpacity(0.2),
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               child: const Icon(
                                 Icons.logout,
                                 color: Colors.white,
                                 size: 20,
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

            // Sub-Assets Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFFF)),
                        ),
                      )
                    : _allSubAssets.isEmpty
                        ? _buildEmptySubAssets()
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _allSubAssets.length,
                            itemBuilder: (context, index) {
                              return _buildSubAssetCard(_allSubAssets[index]);
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
          const Text(
            'No Sub-Assets Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sub-assets from main assets will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

