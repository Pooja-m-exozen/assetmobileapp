// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  late MobileScannerController cameraController;
  bool isScanning = false;
  String? scannedData;
  bool hasScanned = false;
  bool cameraError = false;
  String? errorMessage;
  bool isCameraInitializing = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize with optimized settings for fast scanning
    cameraController = MobileScannerController();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _startScanning() {
    setState(() {
      isScanning = true;
      hasScanned = false;
      scannedData = null;
      cameraError = false;
      errorMessage = null;
      isCameraInitializing = true;
    });
    
    // Reduced delay for faster camera initialization
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          isCameraInitializing = false;
        });
      }
    });
  }

  void _stopScanning() {
    setState(() {
      isScanning = false;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (hasScanned) return; // Early exit if already scanned
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final barcode = barcodes.first;
    if (barcode.rawValue == null || barcode.rawValue!.isEmpty) return;
    
    // Immediately set state and provide haptic feedback for instant response
    HapticFeedback.mediumImpact();
    
    setState(() {
      scannedData = barcode.rawValue;
      hasScanned = true;
      isScanning = false;
    });
    
    // Show result dialog immediately
    _showScanResult(barcode.rawValue!);
  }

  void _showScanResult(String data) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final maxHeight = screenHeight * 0.65; // Reduced to 65%
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.92,
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with Close - Fixed
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00BFFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Scan Result',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          setState(() {
                            scannedData = null;
                            hasScanned = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content - Scrollable with reduced height (show ~4 fields visible)
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 320), // Height for ~4 visible fields
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(18),
                      child: _buildSimpleDataContent(data),
                    ),
                  ),
                ),
                
                // Action Buttons - Fixed at bottom
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              scannedData = null;
                              hasScanned = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF00BFFF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Scan Again',
                            style: TextStyle(
                              color: Color(0xFF00BFFF),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              scannedData = null;
                              hasScanned = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BFFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic>? _parseJsonData(String data) {
    try {
      return json.decode(data);
    } catch (e) {
      return null;
    }
  }

  // Simplified data display showing only essential fields
  Widget _buildSimpleDataContent(String data) {
    final jsonData = _parseJsonData(data);
    
    if (jsonData != null) {
      Map<String, dynamic> assetData = jsonData;
      if (jsonData.containsKey('data') && jsonData['data'] is Map) {
        assetData = jsonData['data'];
      }
      
      // Show all available fields except checksum, timestamp, and url
      List<Widget> infoItems = [];
      
      // Fields to exclude
      List<String> excludedFields = ['checksum', 'timestamp', 'ts', 'url', 'code', 'c', 'parentasset'];
      
      // Collect all fields from asset data and prioritize Tag ID
      List<String> allKeys = assetData.keys.toList();
      
      // Separate Tag ID fields to show first
      List<String> tagIdKeys = [];
      List<String> otherKeys = [];
      
      for (String key in allKeys) {
        String lowerKey = key.toLowerCase();
        if (lowerKey == 't' || lowerKey == 'tagid' || lowerKey == 'id' || 
            lowerKey == 'tag id') {
          tagIdKeys.add(key);
        } else {
          otherKeys.add(key);
        }
      }
      
      // Sort each group alphabetically
      tagIdKeys.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      otherKeys.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      
      // Combine with Tag ID fields first
      List<String> sortedKeys = [...tagIdKeys, ...otherKeys];
      
      for (String field in sortedKeys) {
        // Skip excluded fields
        if (excludedFields.contains(field.toLowerCase())) {
          // Special handling for parentAsset - extract assetType
          if (field.toLowerCase() == 'parentasset') {
            dynamic value = assetData[field];
            if (value is Map && value.containsKey('assetType')) {
              String assetType = value['assetType'].toString();
              if (assetType.isNotEmpty && 
                  assetType.toLowerCase() != 'na' && 
                  assetType.toLowerCase() != 'n/a') {
                infoItems.add(_buildSimpleInfoCard('Asset Type', assetType));
              }
            }
          }
          continue;
        }
        
        dynamic value = assetData[field];
        
        // Skip null, empty, NA values
        if (value == null || 
            value.toString().isEmpty ||
            value.toString().toLowerCase() == 'na' ||
            value.toString().toLowerCase() == 'n/a') {
          continue;
        }
        
        // If value is a Map, create separate cards for each key-value pair
        if (value is Map) {
          value.forEach((key, val) {
            if (val != null && val.toString().isNotEmpty && 
                val.toString().toLowerCase() != 'na' && 
                val.toString().toLowerCase() != 'n/a') {
              String subKey = key.toString();
              String subValue = val.toString();
              String subLabel = _getFieldLabel(subKey);
              infoItems.add(_buildSimpleInfoCard(subLabel, subValue));
            }
          });
          continue;
        }
        
        // Handle different value types
        String displayValue = _formatValue(value);
        
        String label = _getFieldLabel(field);
        
        infoItems.add(
          _buildSimpleInfoCard(label, displayValue),
        );
      }
      
      if (infoItems.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No essential information available',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF666666),
              ),
            ),
          ),
        );
      }
      
      return SingleChildScrollView(
        child: Column(
          children: infoItems,
        ),
      );
    } else {
      // Show raw data if not JSON
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scanned Data',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                data,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSimpleInfoCard(String label, String value) {
    IconData icon = _getFieldIcon(label.toLowerCase());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              size: 20,
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
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) {
      return 'N/A';
    }
    
    // Handle Maps/Objects
    if (value is Map) {
      List<String> parts = [];
      value.forEach((k, v) {
        if (v != null && v.toString().isNotEmpty) {
          parts.add('${k.toString()}: ${v.toString()}');
        }
      });
      return parts.isEmpty ? 'N/A' : parts.join(', ');
    }
    
    // Handle Lists
    if (value is List) {
      return value.map((item) => item.toString()).join(', ');
    }
    
    return value.toString();
  }

  IconData _getFieldIcon(String label) {
    switch (label) {
      case 'tag id':
      case 'id':
        return Icons.qr_code;
      case 'name':
      case 'asset name':
        return Icons.label_outline;
      case 'type':
      case 'category':
        return Icons.category_outlined;
      case 'brand':
        return Icons.business;
      case 'model':
        return Icons.build;
      case 'status':
        return Icons.info_outline;
      case 'priority':
        return Icons.priority_high;
      case 'location':
        return Icons.location_on;
      case 'description':
      case 'brief':
        return Icons.description;
      case 'user':
        return Icons.person_outline;
      case 'timestamp':
        return Icons.access_time;
      case 'checksum':
        return Icons.security;
      default:
        return Icons.info_outline;
    }
  }


  String _getFieldLabel(String key) {
    switch (key.toLowerCase()) {
      case 't': 
      case 'tagid': 
        return 'Tag ID';
      case 'id': 
        return 'ID';
      case 'name': 
      case 'assetname': 
        return 'Name';
      case 'a': 
      case 'type': 
        return 'Type';
      case 'category': 
        return 'Category';
      case 'brand': 
      case 'b': 
        return 'Brand';
      case 'm': 
      case 'model': 
        return 'Model';
      case 'st': 
      case 'status': 
        return 'Status';
      case 'p': 
      case 'priority': 
        return 'Priority';
      case 'l': 
      case 'location': 
        return 'Location';
      case 'parenttagid': 
        return 'Parent Tag ID';
      case 'parentid': 
        return 'Parent ID';
      case 'parentasset': 
        return 'Parent Asset';
      case 'description': 
      case 'desc': 
      case 's': 
        return 'Description';
      case 'brief': 
        return 'Brief';
      case 'u': 
      case 'user': 
        return 'User';
      case 'c': 
        return 'Code';
      case 'url': 
        return 'URL';
      case 'ts': 
      case 'timestamp': 
        return 'Timestamp';
      case 'checksum': 
        return 'Checksum';
      case 'created': 
      case 'createdat': 
        return 'Created At';
      case 'updated': 
      case 'updatedat': 
        return 'Updated At';
      default: 
        // Format key: convert camelCase to Title Case
        return key.replaceAll(RegExp(r'([A-Z])'), r' $1')
                  .trim()
                  .split(' ')
                  .map((word) => word.isEmpty 
                      ? '' 
                      : word[0].toUpperCase() + word.substring(1))
                  .join(' ');
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
                              'QR Code Scanner',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isScanning ? 'Scanning...' : 'Scan and manage your assets',
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
                          if (isScanning)
                            GestureDetector(
                              onTap: _stopScanning,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.stop,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.qr_code_scanner,
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
            
            // Scanner Content
            Expanded(
              child: isScanning ? _buildScannerView() : _buildReadyView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    if (isCameraInitializing) {
      return Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFFF)),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Initializing Camera...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please wait while we set up the camera',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    if (cameraError) {
      return Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: Colors.red[50],
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Camera Error',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unable to access camera. Please check permissions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          cameraError = false;
                          errorMessage = null;
                        });
                        _startScanning();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BFFF),
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.zero,
      child: Stack(
        children: [
          // Camera view - Full screen
          Positioned.fill(
            child: MobileScanner(
              controller: cameraController,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                setState(() {
                  isCameraInitializing = false;
                  cameraError = true;
                  errorMessage = error.toString();
                });
                return Container(
                  color: Colors.red[50],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.camera_alt_outlined,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Camera Not Available',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Professional overlay with cutout
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: ScannerOverlayPainter(),
          ),
          
          // Scanning frame with animated corners
          Center(
            child: _ScanningFrame(),
          ),
          
          // Top section - Instructions
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        color: const Color(0xFF00BFFF),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Position QR code within frame',
                        style: TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Bottom section - Status and controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PulsingDot(
                            color: Colors.greenAccent,
                            size: 8,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Scanning active',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stop button
                    GestureDetector(
                      onTap: _stopScanning,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.stop_circle_rounded,
                              color: Colors.red[600],
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Stop',
                              style: TextStyle(
                                color: Colors.red[600],
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
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
          ),
        ],
      ),
    );
  }


  Widget _buildReadyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                size: 100,
                color: Color(0xFF00BFFF),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Ready to Scan',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Scan QR codes to manage and track assets',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF00BFFF),
                borderRadius: BorderRadius.circular(25),
              ),
              child: ElevatedButton(
                onPressed: _startScanning,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Start Scanning',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pulsing dot animation widget
class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  
  const _PulsingDot({
    required this.color,
    required this.size,
  });
  
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.5 + (_controller.value * 0.5),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

// Scanning line animation widget
class _ScanningLine extends StatefulWidget {
  const _ScanningLine();
  
  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: (_controller.value * 280) - 1,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF00BFFF).withOpacity(0.8),
                  const Color(0xFF00BFFF),
                  const Color(0xFF00BFFF).withOpacity(0.8),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Scanning frame widget with corners and scanning line
class _ScanningFrame extends StatefulWidget {
  const _ScanningFrame();
  
  @override
  State<_ScanningFrame> createState() => _ScanningFrameState();
}

class _ScanningFrameState extends State<_ScanningFrame> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final double frameSize = 280.0;
  final double cornerLength = 30.0;
  final double cornerWidth = 4.0;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: frameSize,
      height: frameSize,
      child: Stack(
        children: [
          // Top-left corner
          Positioned(
            top: 0,
            left: 0,
            child: _CornerIndicator(
              controller: _controller,
              corners: [Corner.top, Corner.left],
              cornerLength: cornerLength,
              cornerWidth: cornerWidth,
            ),
          ),
          // Top-right corner
          Positioned(
            top: 0,
            right: 0,
            child: _CornerIndicator(
              controller: _controller,
              corners: [Corner.top, Corner.right],
              cornerLength: cornerLength,
              cornerWidth: cornerWidth,
            ),
          ),
          // Bottom-left corner
          Positioned(
            bottom: 0,
            left: 0,
            child: _CornerIndicator(
              controller: _controller,
              corners: [Corner.bottom, Corner.left],
              cornerLength: cornerLength,
              cornerWidth: cornerWidth,
            ),
          ),
          // Bottom-right corner
          Positioned(
            bottom: 0,
            right: 0,
            child: _CornerIndicator(
              controller: _controller,
              corners: [Corner.bottom, Corner.right],
              cornerLength: cornerLength,
              cornerWidth: cornerWidth,
            ),
          ),
          // Scanning line
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                top: (_controller.value * frameSize) - 1,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFF00BFFF).withOpacity(0.6),
                        const Color(0xFF00BFFF),
                        const Color(0xFF00BFFF).withOpacity(0.6),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

enum Corner { top, bottom, left, right }

class _CornerIndicator extends StatelessWidget {
  final AnimationController controller;
  final List<Corner> corners;
  final double cornerLength;
  final double cornerWidth;
  
  const _CornerIndicator({
    required this.controller,
    required this.corners,
    required this.cornerLength,
    required this.cornerWidth,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final opacity = 0.5 + (controller.value * 0.5);
        return SizedBox(
          width: cornerLength,
          height: cornerLength,
          child: CustomPaint(
            painter: _CornerPainter(
              corners: corners,
              cornerLength: cornerLength,
              cornerWidth: cornerWidth,
              color: const Color(0xFF00BFFF).withOpacity(opacity),
            ),
          ),
        );
      },
    );
  }
}

class _CornerPainter extends CustomPainter {
  final List<Corner> corners;
  final double cornerLength;
  final double cornerWidth;
  final Color color;
  
  _CornerPainter({
    required this.corners,
    required this.cornerLength,
    required this.cornerWidth,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerWidth
      ..strokeCap = StrokeCap.round;
    
    // Draw horizontal line (top or bottom)
    if (corners.contains(Corner.top)) {
      canvas.drawLine(
        Offset(0, cornerWidth / 2),
        Offset(cornerLength, cornerWidth / 2),
        paint,
      );
    } else if (corners.contains(Corner.bottom)) {
      canvas.drawLine(
        Offset(0, size.height - cornerWidth / 2),
        Offset(cornerLength, size.height - cornerWidth / 2),
        paint,
      );
    }
    
    // Draw vertical line (left or right)
    if (corners.contains(Corner.left)) {
      canvas.drawLine(
        Offset(cornerWidth / 2, 0),
        Offset(cornerWidth / 2, cornerLength),
        paint,
      );
    } else if (corners.contains(Corner.right)) {
      canvas.drawLine(
        Offset(size.width - cornerWidth / 2, 0),
        Offset(size.width - cornerWidth / 2, cornerLength),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Professional overlay painter with proper cutout
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Calculate scanning window position (centered)
    final scanSize = 280.0;
    final left = (size.width - scanSize) / 2;
    final top = (size.height - scanSize) / 2;
    final right = left + scanSize;
    final bottom = top + scanSize;
    
    // Create overlay paint
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    // Create path for overlay with hole
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Create hole for scanning area with rounded corners
    final scanRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, bottom),
      const Radius.circular(16),
    );
    
    path.addRRect(scanRect);
    path.fillType = PathFillType.evenOdd;
    
    // Draw overlay
    canvas.drawPath(path, overlayPaint);
    
    // Draw subtle border around scanning area
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawRRect(scanRect, borderPaint);
    
    // Draw corner guides (subtle)
    final guidePaint = Paint()
      ..color = const Color(0xFF00BFFF).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Draw subtle corner guides
    final guideRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(left - 2, top - 2, right + 2, bottom + 2),
      const Radius.circular(18),
    );
    canvas.drawRRect(guideRect, guidePaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}