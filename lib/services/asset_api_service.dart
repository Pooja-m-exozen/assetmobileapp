import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/asset_models.dart';

class AssetApiService {
  static const String baseUrl = 'https://digitalasset.zenapi.co.in/api';
  static String? _authToken;
  
  // Set authentication token
  static void setAuthToken(String token) {
    _authToken = token;
  }
  
  // Get headers with authentication
  static Map<String, String> _getHeaders() {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }
  
  static Future<AssetResponse> fetchAssetsWithSubAssets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/assets'),
        headers: _getHeaders(),
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');
      print('Auth Token: ${_authToken != null ? 'Present' : 'Missing'}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return AssetResponse.fromJson(jsonData);
      } else {
        // Even if status is not 200, try to parse the response
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          return AssetResponse.fromJson(jsonData);
        } catch (e) {
          throw Exception('Failed to load assets: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      print('Network error details: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<AssetResponse> fetchAssetsWithoutSubAssets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/assets?includeSubAssets=false'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return AssetResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load assets: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Asset?> fetchAssetById(String assetId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/assets/$assetId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Asset.fromJson(jsonData);
      } else {
        throw Exception('Failed to load asset: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
