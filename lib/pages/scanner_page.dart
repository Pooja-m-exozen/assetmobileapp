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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Minimal Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00BFFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Asset Scan Result',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          setState(() {
                            scannedData = null;
                            hasScanned = false;
                          });
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Table Content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: _buildTableDataContent(data),
                  ),
                ),
                
                // Simple Actions
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Scan Again',
                            style: TextStyle(
                              color: Color(0xFF00BFFF),
                              fontWeight: FontWeight.w600,
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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

  Widget _buildTableDataContent(String data) {
    final jsonData = _parseJsonData(data);
    
    if (jsonData != null) {
      // Check if it's the new data structure with 'data' field
      Map<String, dynamic> assetData = jsonData;
      if (jsonData.containsKey('data') && jsonData['data'] is Map) {
        assetData = jsonData['data'];
      }
      
      // Define important fields to show
      List<String> importantFields = [
        't', 'tagid', 'id', 'a', 'assetname', 'name', 'type', 'category',
        's', 'description', 'brief', 'm', 'model', 'brand', 'st', 'status',
        'p', 'priority', 'l', 'location', 'u', 'user'
      ];
      
      List<TableRow> tableRows = [];
      
      // Add important fields first
      for (String field in importantFields) {
        if (assetData.containsKey(field) && assetData[field] != null && assetData[field].toString().isNotEmpty) {
          String label = _getFieldLabel(field);
          String formattedValue = _formatFieldValue(field, assetData[field]);
          
          tableRows.add(
            TableRow(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[200]!,
                    width: 0.5,
                  ),
                ),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  child: SelectableText(
                    formattedValue,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF4A4A4A),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }
      
      // Add other fields if any
      assetData.forEach((key, value) {
        if (!importantFields.contains(key.toLowerCase()) && 
            value != null && value.toString().isNotEmpty) {
          String label = _getFieldLabel(key);
          String formattedValue = _formatFieldValue(key, value);
          
          tableRows.add(
            TableRow(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[200]!,
                    width: 0.5,
                  ),
                ),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  child: SelectableText(
                    formattedValue,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF4A4A4A),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      });
      
      if (tableRows.isEmpty) {
        return const Center(
          child: Text(
            'No data available',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
        );
      }
      
      return SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.0), // Field column
              1: FlexColumnWidth(1.8), // Value column
            },
            border: TableBorder.all(
              color: Colors.grey[200]!,
              width: 0.5,
              borderRadius: BorderRadius.circular(16),
            ),
            children: tableRows,
          ),
        ),
      );
    } else {
      // Display raw data for non-JSON content
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scanned Data',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              data,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      );
    }
  }

  String _getFieldLabel(String key) {
    switch (key.toLowerCase()) {
      case 't': return 'Tag ID';
      case 'a': return 'Asset Type';
      case 's': return 'Description';
      case 'b': return 'Brief';
      case 'm': return 'Model';
      case 'st': return 'Status';
      case 'p': return 'Priority';
      case 'l': return 'Location';
      case 'u': return 'User';
      case 'url': return 'URL';
      case 'ts': return 'Timestamp';
      case 'c': return 'Code';
      case 'tagid': return 'Tag ID';
      case 'assetname': return 'Asset Name';
      case 'type': return 'Type';
      case 'category': return 'Category';
      case 'brand': return 'Brand';
      case 'model': return 'Model';
      case 'status': return 'Status';
      case 'priority': return 'Priority';
      case 'location': return 'Location';
      case 'parenttagid': return 'Parent Tag ID';
      case 'parentasset': return 'Parent Asset';
      case 'timestamp': return 'Timestamp';
      case 'checksum': return 'Checksum';
      case 'id': return 'ID';
      case 'name': return 'Name';
      case 'title': return 'Title';
      default: return key.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim();
    }
  }

  String _formatFieldValue(String key, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Not specified';
    }
    
    // Handle nested objects
    if (value is Map) {
      List<String> parts = [];
      value.forEach((k, v) {
        if (v != null && v.toString().isNotEmpty) {
          // Skip latitude and longitude for location fields
          if (key.toLowerCase() == 'location' && 
              (k.toString().toLowerCase() == 'latitude' || 
               k.toString().toLowerCase() == 'longitude')) {
            return;
          }
          parts.add('${_getFieldLabel(k)}: ${v.toString()}');
        }
      });
      return parts.join(', ');
    }
    
    // Handle arrays
    if (value is List) {
      return value.map((item) => item.toString()).join(', ');
    }
    
    // Format specific fields
    if (key.toLowerCase() == 'timestamp') {
      return _formatTimestamp(value);
    }
    
    if (key.toLowerCase() == 'status' || key.toLowerCase() == 'priority') {
      return value.toString().toUpperCase();
    }
    
    return value.toString();
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      int timestampInt;
      if (timestamp is int) {
        timestampInt = timestamp;
      } else if (timestamp is String) {
        timestampInt = int.parse(timestamp);
      } else {
        return timestamp.toString();
      }
      
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestampInt);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section (like dashboard)
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BFFF), Color(0xFF1E90FF)],
                ),
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
                child: Text(
                  'Start Scanning',
                  style: const TextStyle(
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