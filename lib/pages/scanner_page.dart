// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = false;
  String? scannedData;
  bool hasScanned = false;
  bool cameraError = false;
  String? errorMessage;
  bool isCameraInitializing = false;

  @override
  void initState() {
    super.initState();
    // Don't check camera availability on init - let user start scanning when ready
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
    
    // Remove loading state after a short delay to show camera
    Future.delayed(const Duration(milliseconds: 500), () {
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
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && !hasScanned) {
        setState(() {
          scannedData = barcode.rawValue;
          hasScanned = true;
          isScanning = false;
        });
        
        // Show result dialog
        _showScanResult(barcode.rawValue!);
      }
    }
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
      List<String> excludedFields = ['checksum', 'timestamp', 'ts', 'url', 'code', 'c'];
      
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
        return key.replaceAll(RegExp(r'([A-Z])'), ' \$1')
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
        child: Stack(
          children: [
            // Camera view
            MobileScanner(
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
            
            // Dark overlay with transparent scanning area
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            
            // Transparent scanning window
            Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF00BFFF),
                    width: 3,
                  ),
                ),
                child: Stack(
                  children: [
                    // Corner indicators (Google Pay style)
                    Positioned(
                      top: -2,
                      left: -2,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00BFFF),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00BFFF),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      left: -2,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00BFFF),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00BFFF),
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Scanning line animation
            Center(
              child: Container(
                width: 280,
                height: 2,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color(0xFF00BFFF),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
                child: AnimatedContainer(
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  transform: Matrix4.translationValues(0, -140, 0),
                ),
              ),
            ),
            
            // Top instruction
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  'Point your camera at a QR code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            // Bottom instruction
            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  'QR code will be scanned automatically',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
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