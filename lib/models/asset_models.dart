// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

class AssetResponse {
  final bool success;
  final List<Asset> assets;
  final bool includeSubAssets;
  final SubAssetInfo? subAssetInfo;
  final Pagination? pagination;

  AssetResponse({
    required this.success,
    required this.assets,
    required this.includeSubAssets,
    this.subAssetInfo,
    this.pagination,
  });

  factory AssetResponse.fromJson(Map<String, dynamic> json) {
    print('Raw JSON received: $json');
    
    List<Asset> assetsList = [];
    if (json['assets'] != null) {
      try {
        if (json['assets'] is List) {
          assetsList = (json['assets'] as List)
              .map((assetJson) {
                print('Processing asset: $assetJson');
                return Asset.fromJson(assetJson as Map<String, dynamic>);
              })
              .toList();
        } else {
          print('Assets field is not a list: ${json['assets']}');
        }
      } catch (e) {
        print('Error parsing assets: $e');
        print('Raw assets data: ${json['assets']}');
        assetsList = [];
      }
    } else {
      print('No assets field found in response');
    }
    
    return AssetResponse(
      success: json['success'] ?? false,
      assets: assetsList,
      includeSubAssets: json['includeSubAssets'] ?? false,
      subAssetInfo: json['subAssetInfo'] != null 
          ? SubAssetInfo.fromJson(json['subAssetInfo']) 
          : null,
      pagination: json['pagination'] != null 
          ? Pagination.fromJson(json['pagination']) 
          : null,
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 1,
    );
  }
}

class Asset {
  final Location? location;
  final Project? project;
  final Compliance? compliance;
  final Financial? financial;
  final SubAssets? subAssets;
  final String? tagId;
  final String? assetName;
  final String? description;
  final String? category;
  final String? brand;
  final String? model;
  final String? capacity;
  final String? locationString;
  final String? digitalTagType;
  final List<dynamic>? scanHistory;
  final String? status;
  final String? priority;
  final String? id;
  final List<dynamic>? replacementHistory;
  final String? createdAt;
  final String? updatedAt;
  final bool? hasDigitalAssets;

  Asset({
    this.location,
    this.project,
    this.compliance,
    this.financial,
    this.subAssets,
    this.tagId,
    this.assetName,
    this.description,
    this.category,
    this.brand,
    this.model,
    this.capacity,
    this.locationString,
    this.digitalTagType,
    this.scanHistory,
    this.status,
    this.priority,
    this.id,
    this.replacementHistory,
    this.createdAt,
    this.updatedAt,
    this.hasDigitalAssets,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    print('Processing Asset JSON: $json');
    
    try {
      return Asset(
        location: json['location'] != null ? Location.fromJson(json['location']) : null,
        project: json['project'] != null ? Project.fromJson(json['project']) : null,
        compliance: json['compliance'] != null ? Compliance.fromJson(json['compliance']) : null,
        financial: json['financial'] != null ? Financial.fromJson(json['financial']) : null,
        subAssets: json['subAssets'] != null ? SubAssets.fromJson(json['subAssets']) : null,
        tagId: json['tagId']?.toString(),
        assetName: json['assetName']?.toString() ?? json['assetType']?.toString(),
        description: json['description']?.toString(),
        category: json['category']?.toString() ?? json['subcategory']?.toString(),
        brand: json['brand']?.toString(),
        model: json['model']?.toString(),
        capacity: json['capacity']?.toString(),
        locationString: json['location']?.toString() ?? json['mobilityCategory']?.toString(),
        digitalTagType: json['digitalTagType']?.toString(),
        scanHistory: json['scanHistory'],
        status: json['status']?.toString(),
        priority: json['priority']?.toString(),
        id: json['_id']?.toString(),
        replacementHistory: json['replacementHistory'],
        createdAt: json['createdAt']?.toString(),
        updatedAt: json['updatedAt']?.toString(),
        hasDigitalAssets: json['hasDigitalAssets'] ?? false,
      );
    } catch (e) {
      print('Error creating Asset from JSON: $e');
      print('Problematic JSON: $json');
      // Return a basic asset with available data
      return Asset(
        tagId: json['tagId']?.toString() ?? 'Unknown',
        assetName: json['assetName']?.toString() ?? json['assetType']?.toString() ?? 'Unknown Asset',
        status: json['status']?.toString() ?? 'Unknown',
        category: json['category']?.toString() ?? json['subcategory']?.toString() ?? 'Unknown',
        brand: json['brand']?.toString() ?? 'Unknown',
        model: json['model']?.toString() ?? 'Unknown',
        locationString: json['location']?.toString() ?? json['mobilityCategory']?.toString() ?? 'Unknown',
      );
    }
  }

  // Display properties for UI
  String get displayName => assetName ?? 'Unknown Asset';
  String get displayId => tagId ?? 'N/A';
  String get displayLocation => locationString ?? 'Unknown Location';
  String get displayCategory => category ?? 'Unknown Category';
  String get displayBrand => brand ?? 'Unknown Brand';
  String get displayModel => model ?? 'N/A';
  String get displayStatus => status ?? 'Unknown';

  // Status color based on status
  Color get statusColor {
    switch (status?.toLowerCase()) {
      case 'active':
        return const Color(0xFF4CAF50); // Green
      case 'inactive':
        return const Color(0xFF9E9E9E); // Grey
      case 'maintenance':
        return const Color(0xFFFF9800); // Orange
      case 'retired':
        return const Color(0xFFF44336); // Red
      case 'procured':
        return const Color(0xFF2196F3); // Blue
      default:
        return const Color(0xFF9E9E9E); // Default grey
    }
  }
}

class Location {
  final String? latitude;
  final String? longitude;
  final String? building;
  final String? floor;
  final String? room;

  Location({
    this.latitude,
    this.longitude,
    this.building,
    this.floor,
    this.room,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      building: json['building']?.toString(),
      floor: json['floor']?.toString(),
      room: json['room']?.toString(),
    );
  }
}

class Project {
  final String? projectName;

  Project({this.projectName});

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      projectName: json['projectName'],
    );
  }
}

class Compliance {
  final List<dynamic>? certifications;
  final List<dynamic>? expiryDates;
  final List<dynamic>? regulatoryRequirements;

  Compliance({
    this.certifications,
    this.expiryDates,
    this.regulatoryRequirements,
  });

  factory Compliance.fromJson(Map<String, dynamic> json) {
    return Compliance(
      certifications: json['certifications'],
      expiryDates: json['expiryDates'],
      regulatoryRequirements: json['regulatoryRequirements'],
    );
  }
}

class Financial {
  final PurchaseOrder? purchaseOrder;
  final Lifecycle? lifecycle;
  final List<dynamic>? replacementHistory;

  Financial({
    this.purchaseOrder,
    this.lifecycle,
    this.replacementHistory,
  });

  factory Financial.fromJson(Map<String, dynamic> json) {
    return Financial(
      purchaseOrder: json['purchaseOrder'] != null 
          ? PurchaseOrder.fromJson(json['purchaseOrder']) 
          : null,
      lifecycle: json['lifecycle'] != null 
          ? Lifecycle.fromJson(json['lifecycle']) 
          : null,
      replacementHistory: json['replacementHistory'],
    );
  }
}

class PurchaseOrder {
  final String? currency;

  PurchaseOrder({this.currency});

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      currency: json['currency'],
    );
  }
}

class Lifecycle {
  final String? status;

  Lifecycle({this.status});

  factory Lifecycle.fromJson(Map<String, dynamic> json) {
    return Lifecycle(
      status: json['status'],
    );
  }
}

class SubAssets {
  final List<dynamic>? movable;
  final List<SubAsset>? immovable;

  SubAssets({
    this.movable,
    this.immovable,
  });

  factory SubAssets.fromJson(Map<String, dynamic> json) {
    List<SubAsset> immovableList = [];
    if (json['immovable'] != null) {
      try {
        immovableList = (json['immovable'] as List)
            .map((subAssetJson) => SubAsset.fromJson(subAssetJson as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Error parsing immovable sub-assets: $e');
        immovableList = [];
      }
    }
    
    return SubAssets(
      movable: json['movable'],
      immovable: immovableList,
    );
  }
}

class SubAsset {
  final DigitalAssets? digitalAssets;
  final Inventory? inventory;
  final PurchaseOrder? purchaseOrder;
  final Lifecycle? lifecycle;
  final String? tagId;
  final String? assetName;
  final String? description;
  final String? category;
  final String? brand;
  final String? model;
  final String? capacity;
  final String? locationString;
  final String? digitalTagType;
  final List<dynamic>? scanHistory;
  final String? status;
  final String? priority;
  final String? id;
  final List<dynamic>? replacementHistory;
  final String? createdAt;
  final String? updatedAt;
  final bool? hasDigitalAssets;

  SubAsset({
    this.digitalAssets,
    this.inventory,
    this.purchaseOrder,
    this.lifecycle,
    this.tagId,
    this.assetName,
    this.description,
    this.category,
    this.brand,
    this.model,
    this.capacity,
    this.locationString,
    this.digitalTagType,
    this.scanHistory,
    this.status,
    this.priority,
    this.id,
    this.replacementHistory,
    this.createdAt,
    this.updatedAt,
    this.hasDigitalAssets,
  });

  factory SubAsset.fromJson(Map<String, dynamic> json) {
    return SubAsset(
      digitalAssets: json['digitalAssets'] != null 
          ? DigitalAssets.fromJson(json['digitalAssets']) 
          : null,
      inventory: json['inventory'] != null 
          ? Inventory.fromJson(json['inventory']) 
          : null,
      purchaseOrder: json['purchaseOrder'] != null 
          ? PurchaseOrder.fromJson(json['purchaseOrder']) 
          : null,
      lifecycle: json['lifecycle'] != null 
          ? Lifecycle.fromJson(json['lifecycle']) 
          : null,
      tagId: json['tagId'],
      assetName: json['assetName'],
      description: json['description'],
      category: json['category'],
      brand: json['brand'],
      model: json['model'],
      capacity: json['capacity'],
      locationString: json['location'],
      digitalTagType: json['digitalTagType'],
      scanHistory: json['scanHistory'],
      status: json['status'],
      priority: json['priority'],
      id: json['_id'],
      replacementHistory: json['replacementHistory'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      hasDigitalAssets: json['hasDigitalAssets'],
    );
  }

  // Display properties for UI
  String get displayName => assetName ?? 'Unknown Sub-Asset';
  String get displayId => tagId ?? 'N/A';
  String get displayLocation => locationString ?? 'Unknown Location';
  String get displayStatus => status ?? 'Unknown';

  // Status color based on status
  Color get statusColor {
    switch (status?.toLowerCase()) {
      case 'active':
        return const Color(0xFF4CAF50); // Green
      case 'inactive':
        return const Color(0xFF9E9E9E); // Grey
      case 'maintenance':
        return const Color(0xFFFF9800); // Orange
      case 'retired':
        return const Color(0xFFF44336); // Red
      case 'procured':
        return const Color(0xFF2196F3); // Blue
      default:
        return const Color(0xFF9E9E9E); // Default grey
    }
  }
}

class DigitalAssets {
  final QrCode? qrCode;
  final Barcode? barcode;

  DigitalAssets({
    this.qrCode,
    this.barcode,
  });

  factory DigitalAssets.fromJson(Map<String, dynamic> json) {
    return DigitalAssets(
      qrCode: json['qrCode'] != null ? QrCode.fromJson(json['qrCode']) : null,
      barcode: json['barcode'] != null ? Barcode.fromJson(json['barcode']) : null,
    );
  }
}

class QrCode {
  final String? url;
  final Map<String, dynamic>? data;
  final String? generatedAt;

  QrCode({
    this.url,
    this.data,
    this.generatedAt,
  });

  factory QrCode.fromJson(Map<String, dynamic> json) {
    return QrCode(
      url: json['url'],
      data: json['data'],
      generatedAt: json['generatedAt'],
    );
  }
}

class Barcode {
  final String? url;
  final String? data;
  final String? generatedAt;

  Barcode({
    this.url,
    this.data,
    this.generatedAt,
  });

  factory Barcode.fromJson(Map<String, dynamic> json) {
    return Barcode(
      url: json['url'],
      data: json['data'],
      generatedAt: json['generatedAt'],
    );
  }
}

class Inventory {
  final List<dynamic>? consumables;
  final List<dynamic>? spareParts;
  final List<dynamic>? tools;
  final List<dynamic>? operationalSupply;

  Inventory({
    this.consumables,
    this.spareParts,
    this.tools,
    this.operationalSupply,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      consumables: json['consumables'],
      spareParts: json['spareParts'],
      tools: json['tools'],
      operationalSupply: json['operationalSupply'],
    );
  }
}

class SubAssetInfo {
  final String? message;
  final String? note;

  SubAssetInfo({
    this.message,
    this.note,
  });

  factory SubAssetInfo.fromJson(Map<String, dynamic> json) {
    return SubAssetInfo(
      message: json['message'],
      note: json['note'],
    );
  }
}
