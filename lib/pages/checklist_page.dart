// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/asset_models.dart';
import '../services/asset_api_service.dart';

class ChecklistPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const ChecklistPage({super.key, this.userData});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  List<Asset> _allAssets = [];
  List<AssetChecklist> _allChecklists = [];
  List<AssetChecklist> _filteredChecklists = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedAssetName;
  String? _selectedChecklistType;
  
  final List<String> _checklistTypes = [
    'All Types',
    'Inspection',
    'Maintenance',
    'Compliance',
    'Safety',
    'Pre-Deployment',
    'Transfer',
  ];

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  @override
  void dispose() {
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
      
      while (hasMorePages) {
        final AssetResponse response = await AssetApiService.fetchAssetsWithSubAssets(
          page: currentPage,
          limit: 10,
        );
        
        allAssets.addAll(response.assets);
        
        if (response.pagination != null) {
          hasMorePages = currentPage < response.pagination!.pages;
        } else {
          hasMorePages = false;
        }
        
        currentPage++;
        if (currentPage > 10) hasMorePages = false;
      }

      // Filter by user's project if available
      if (widget.userData?['projectName'] != null) {
        final projectName = widget.userData!['projectName']?.toString();
        if (projectName != null && projectName.isNotEmpty) {
          allAssets = allAssets.where((asset) => 
            asset.project?.projectName == projectName
          ).toList();
        }
      }

      setState(() {
        _allAssets = allAssets;
        _generateChecklistsForAssets(allAssets);
        _isLoading = false;
      });
      
      // Load saved checklist states after generating checklists
      _loadSavedChecklistStates();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _generateChecklistsForAssets(List<Asset> assets) {
    List<AssetChecklist> checklists = [];
    
    for (var asset in assets) {
      // Generate different types of checklists for each asset
      checklists.add(AssetChecklist(
        id: '${asset.id}_inspection',
        assetId: asset.id ?? '',
        assetName: asset.displayName,
        assetTagId: asset.displayId,
        type: 'Inspection',
        title: '${asset.displayName} - Inspection Checklist',
        description: 'Regular inspection checklist for ${asset.displayName}',
        items: _getInspectionItems(asset),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ));

      checklists.add(AssetChecklist(
        id: '${asset.id}_maintenance',
        assetId: asset.id ?? '',
        assetName: asset.displayName,
        assetTagId: asset.displayId,
        type: 'Maintenance',
        title: '${asset.displayName} - Maintenance Checklist',
        description: 'Scheduled maintenance checklist for ${asset.displayName}',
        items: _getMaintenanceItems(asset),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ));

      if (asset.compliance != null) {
        checklists.add(AssetChecklist(
          id: '${asset.id}_compliance',
          assetId: asset.id ?? '',
          assetName: asset.displayName,
          assetTagId: asset.displayId,
          type: 'Compliance',
          title: '${asset.displayName} - Compliance Checklist',
          description: 'Compliance and regulatory checklist for ${asset.displayName}',
          items: _getComplianceItems(asset),
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ));
      }

      checklists.add(AssetChecklist(
        id: '${asset.id}_safety',
        assetId: asset.id ?? '',
        assetName: asset.displayName,
        assetTagId: asset.displayId,
        type: 'Safety',
        title: '${asset.displayName} - Safety Checklist',
        description: 'Safety inspection checklist for ${asset.displayName}',
        items: _getSafetyItems(asset),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ));
    }

    setState(() {
      _allChecklists = checklists;
      _filteredChecklists = checklists;
    });
  }

  List<ChecklistItem> _getInspectionItems(Asset asset) {
    return [
      ChecklistItem(
        id: '1',
        title: 'Visual inspection of physical condition',
        description: 'Check for any visible damage or wear',
        isCompleted: true,
      ),
      ChecklistItem(
        id: '2',
        title: 'Verify asset tag is present and readable',
        description: 'Ensure tag ID: ${asset.displayId} is visible',
        isCompleted: true,
      ),
      ChecklistItem(
        id: '3',
        title: 'Check location accuracy',
        description: 'Verify asset is in correct location',
        isCompleted: false,
      ),
      ChecklistItem(
        id: '4',
        title: 'Document current status',
        description: 'Record current status: ${asset.displayStatus}',
        isCompleted: false,
      ),
      ChecklistItem(
        id: '5',
        title: 'Review compliance status',
        description: 'Check compliance certifications',
        isCompleted: asset.compliance != null,
      ),
    ];
  }

  List<ChecklistItem> _getMaintenanceItems(Asset asset) {
    return [
      ChecklistItem(
        id: '1',
        title: 'Perform scheduled maintenance',
        description: 'Complete scheduled maintenance tasks',
        isCompleted: false,
      ),
      ChecklistItem(
        id: '2',
        title: 'Check and replace consumables',
        description: 'Review consumables inventory',
        isCompleted: false,
      ),
      ChecklistItem(
        id: '3',
        title: 'Update maintenance log',
        description: 'Document maintenance activities',
        isCompleted: false,
      ),
      ChecklistItem(
        id: '4',
        title: 'Verify spare parts availability',
        description: 'Check spare parts inventory',
        isCompleted: true,
      ),
    ];
  }

  List<ChecklistItem> _getComplianceItems(Asset asset) {
    return [
      ChecklistItem(
        id: '1',
        title: 'Verify certifications are valid',
        description: 'Check certification expiry dates',
        isCompleted: asset.compliance?.certifications != null,
      ),
      ChecklistItem(
        id: '2',
        title: 'Review regulatory requirements',
        description: 'Ensure all requirements are met',
        isCompleted: false,
      ),
      ChecklistItem(
        id: '3',
        title: 'Update compliance documentation',
        description: 'Document compliance status',
        isCompleted: false,
      ),
    ];
  }

  List<ChecklistItem> _getSafetyItems(Asset asset) {
    return [
      ChecklistItem(
        id: '1',
        title: 'Safety equipment check',
        description: 'Verify all safety equipment is present',
        isCompleted: true,
      ),
      ChecklistItem(
        id: '2',
        title: 'Hazard assessment',
        description: 'Identify and document potential hazards',
        isCompleted: false,
      ),
      ChecklistItem(
        id: '3',
        title: 'Emergency procedures review',
        description: 'Verify emergency procedures are up to date',
        isCompleted: true,
      ),
      ChecklistItem(
        id: '4',
        title: 'Safety training verification',
        description: 'Confirm personnel training is current',
        isCompleted: false,
      ),
    ];
  }

  void _filterChecklists() {
    List<AssetChecklist> filtered = _allChecklists;

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((checklist) {
        return checklist.title.toLowerCase().contains(query) ||
            checklist.assetName.toLowerCase().contains(query) ||
            checklist.assetTagId.toLowerCase().contains(query) ||
            checklist.description.toLowerCase().contains(query);
      }).toList();
    }

    // Apply asset filter
    if (_selectedAssetName != null && _selectedAssetName!.isNotEmpty) {
      filtered = filtered.where((checklist) {
        return checklist.assetName == _selectedAssetName;
      }).toList();
    }

    // Apply type filter
    if (_selectedChecklistType != null && 
        _selectedChecklistType!.isNotEmpty && 
        _selectedChecklistType != 'All Types') {
      filtered = filtered.where((checklist) {
        return checklist.type == _selectedChecklistType;
      }).toList();
    }

    setState(() {
      _filteredChecklists = filtered;
    });
  }

  List<String> get _assetNames {
    return _allAssets.map((asset) => asset.displayName).toSet().toList()..sort();
  }

  double _getCompletionPercentage(AssetChecklist checklist) {
    if (checklist.items.isEmpty) return 0.0;
    final completed = checklist.items.where((item) => item.isCompleted).length;
    return completed / checklist.items.length;
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
                              'Asset Checklists',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Manage and track your checklists',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.checklist,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search and Filter Section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
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
                      onChanged: (_) => _filterChecklists(),
                      decoration: InputDecoration(
                        hintText: 'Search checklists...',
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
                                  _filterChecklists();
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
                  const SizedBox(height: 12),
                  // Filter Row
                  Row(
                    children: [
                      Expanded(
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
                            underline: Container(),
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
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('All Assets'),
                                ),
                              ),
                              ..._assetNames.map((name) {
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
                            onChanged: (value) {
                              setState(() {
                                _selectedAssetName = value;
                              });
                              _filterChecklists();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
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
                            value: _selectedChecklistType,
                            isExpanded: true,
                            underline: Container(),
                            hint: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'All Types',
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
                            items: _checklistTypes.map((type) {
                              return DropdownMenuItem<String?>(
                                value: type == 'All Types' ? null : type,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(type),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedChecklistType = value;
                              });
                              _filterChecklists();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Statistics Summary
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${_allChecklists.length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00BFFF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Checklists',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Column(
                    children: [
                      Text(
                        _allChecklists.isEmpty
                            ? '0%'
                            : '${(_allChecklists.map((c) => _getCompletionPercentage(c)).reduce((a, b) => a + b) / _allChecklists.length * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFC107),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Avg. Completion',
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

            // Checklists Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _filteredChecklists.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadAssets,
                              color: const Color(0xFF00BFFF),
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: _filteredChecklists.length,
                                itemBuilder: (context, index) {
                                  return _buildChecklistCard(_filteredChecklists[index]);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistCard(AssetChecklist checklist) {
    final completion = _getCompletionPercentage(checklist);
    
    return GestureDetector(
      onTap: () => _showChecklistDetails(checklist),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        checklist.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${checklist.assetName} • ${checklist.assetTagId}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(completion * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: completion == 1.0 ? const Color(0xFF4CAF50) : const Color(0xFF00BFFF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(checklist.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    checklist.type,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getTypeColor(checklist.type),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: completion,
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completion == 1.0 ? const Color(0xFF4CAF50) : const Color(0xFF00BFFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Inspection':
        return const Color(0xFF2196F3);
      case 'Maintenance':
        return const Color(0xFFFF9800);
      case 'Compliance':
        return const Color(0xFF9C27B0);
      case 'Safety':
        return const Color(0xFFF44336);
      case 'Pre-Deployment':
        return const Color(0xFF00BFFF);
      case 'Transfer':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF00BFFF);
    }
  }

  // Save checklist state to SharedPreferences
  Future<void> _saveChecklistState(AssetChecklist checklist) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final checklistData = {
        'checklistId': checklist.id,
        'items': checklist.items.map((item) => {
          'id': item.id,
          'isCompleted': item.isCompleted,
        }).toList(),
        'submittedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString('checklist_${checklist.id}', json.encode(checklistData));
    } catch (e) {
      print('Error saving checklist state: $e');
    }
  }

  // Load saved checklist states from SharedPreferences
  Future<void> _loadSavedChecklistStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      for (var checklist in _allChecklists) {
        final savedData = prefs.getString('checklist_${checklist.id}');
        if (savedData != null) {
          final data = json.decode(savedData) as Map<String, dynamic>;
          final savedItems = data['items'] as List;
          
          for (var savedItem in savedItems) {
            final itemId = savedItem['id'] as String;
            final isCompleted = savedItem['isCompleted'] as bool;
            
            final item = checklist.items.firstWhere(
              (i) => i.id == itemId,
              orElse: () => ChecklistItem(id: itemId, title: '', description: '', isCompleted: false),
            );
            if (item.id == itemId) {
              item.isCompleted = isCompleted;
            }
          }
        }
      }
      
      setState(() {
        _filteredChecklists = List.from(_allChecklists);
      });
    } catch (e) {
      print('Error loading checklist states: $e');
    }
  }

  void _showChecklistDetails(AssetChecklist checklist) {
    // Create a copy to work with so we don't modify the original until submit
    final checklistCopy = AssetChecklist(
      id: checklist.id,
      assetId: checklist.assetId,
      assetName: checklist.assetName,
      assetTagId: checklist.assetTagId,
      type: checklist.type,
      title: checklist.title,
      description: checklist.description,
      items: checklist.items.map((item) => ChecklistItem(
        id: item.id,
        title: item.title,
        description: item.description,
        isCompleted: item.isCompleted,
      )).toList(),
      createdAt: checklist.createdAt,
      updatedAt: checklist.updatedAt,
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: _ChecklistDetailsDialog(
          checklist: checklistCopy,
          onItemToggle: (itemId) {
            // No-op - dialog manages its own state
          },
          onSubmit: (dialogChecklist) async {
            // Update original checklist with dialog's state
            for (var i = 0; i < checklist.items.length; i++) {
              checklist.items[i].isCompleted = dialogChecklist.items[i].isCompleted;
            }
            
            // Save to SharedPreferences
            await _saveChecklistState(checklist);
            
            // Update filtered list
            setState(() {
              _filteredChecklists = List.from(_allChecklists);
            });
            
            Navigator.of(context).pop();
            
            // Show success message
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checklist submitted successfully!'),
                  backgroundColor: Color(0xFF4CAF50),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
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
            'Loading checklists...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
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
          const Text(
            'Failed to load checklists',
            style: TextStyle(
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
    final hasFilters = _searchController.text.isNotEmpty ||
        _selectedAssetName != null ||
        _selectedChecklistType != null;

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
              Icons.checklist_outlined,
              color: Color(0xFF00BFFF),
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hasFilters ? 'No Matching Checklists' : 'No Checklists Found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try adjusting your search or filter settings'
                : 'Checklists will appear here once assets are loaded',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedAssetName = null;
                  _selectedChecklistType = null;
                });
                _filterChecklists();
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
            ),
          ],
        ],
      ),
    );
  }
}

// Checklist Models
class AssetChecklist {
  final String id;
  final String assetId;
  final String assetName;
  final String assetTagId;
  final String type;
  final String title;
  final String description;
  final List<ChecklistItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  AssetChecklist({
    required this.id,
    required this.assetId,
    required this.assetName,
    required this.assetTagId,
    required this.type,
    required this.title,
    required this.description,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });
}

class ChecklistItem {
  final String id;
  final String title;
  final String description;
  bool isCompleted;

  ChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
  });
}

// Checklist Details Dialog
class _ChecklistDetailsDialog extends StatefulWidget {
  final AssetChecklist checklist;
  final Function(String) onItemToggle;
  final Function(AssetChecklist)? onSubmit;

  const _ChecklistDetailsDialog({
    required this.checklist,
    required this.onItemToggle,
    this.onSubmit,
  });

  @override
  State<_ChecklistDetailsDialog> createState() => _ChecklistDetailsDialogState();
}

class _ChecklistDetailsDialogState extends State<_ChecklistDetailsDialog> {
  late AssetChecklist _checklist;

  @override
  void initState() {
    super.initState();
    // Create a working copy
    _checklist = AssetChecklist(
      id: widget.checklist.id,
      assetId: widget.checklist.assetId,
      assetName: widget.checklist.assetName,
      assetTagId: widget.checklist.assetTagId,
      type: widget.checklist.type,
      title: widget.checklist.title,
      description: widget.checklist.description,
      items: widget.checklist.items.map((item) => ChecklistItem(
        id: item.id,
        title: item.title,
        description: item.description,
        isCompleted: item.isCompleted,
      )).toList(),
      createdAt: widget.checklist.createdAt,
      updatedAt: widget.checklist.updatedAt,
    );
  }

  void _toggleItem(String itemId) {
    final item = _checklist.items.firstWhere((i) => i.id == itemId);
    // Only allow checking, not unchecking - once completed, it stays completed
    if (!item.isCompleted) {
      setState(() {
        item.isCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    final completion = _checklist.items.isEmpty
        ? 0.0
        : _checklist.items.where((item) => item.isCompleted).length /
            _checklist.items.length;

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
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF00BFFF),
              borderRadius: const BorderRadius.only(
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
                        'Checklist Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _checklist.title,
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
                  // Progress and Asset Info
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Progress',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: completion,
                                minHeight: 8,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  completion == 1.0
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFF00BFFF),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_checklist.items.where((item) => item.isCompleted).length} of ${_checklist.items.length} items',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Asset',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _checklist.assetName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _checklist.assetTagId,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Checklist Items
                  const SizedBox(height: 8),
                  ..._checklist.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildChecklistItem(context, item, index + 1);
                  }),
                  const SizedBox(height: 20),
                  
                  // Submit Button
                  if (widget.onSubmit != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => widget.onSubmit!(_checklist),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BFFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Submit Checklist',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(BuildContext context, ChecklistItem item, int number) {
    final isCompleted = item.isCompleted;
    
    return GestureDetector(
      onTap: isCompleted ? null : () => _toggleItem(item.id),
      child: Opacity(
        opacity: isCompleted ? 0.7 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          color: Colors.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Container(
                margin: const EdgeInsets.only(right: 16, top: 2),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF4CAF50)
                      : Colors.transparent,
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF4CAF50)
                        : Colors.grey[400]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFFF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#$number',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00BFFF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? Colors.grey[500]
                          : const Color(0xFF1A1A1A),
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
