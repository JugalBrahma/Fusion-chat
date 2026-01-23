import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class AnalyticsApiService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> getFolderAnalytics(String folderId) async {
    try {
      // Get current user token
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final token = await user.getIdToken();
      
      print('Fetching analytics for folder: $folderId');
      print('Making request to: ${ApiConfig.baseUrl}/api/analytics/$folderId');
      
      // Make API call
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/analytics/$folderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load analytics: ${response.body}');
      }
    } catch (e) {
      print('Error fetching analytics: $e');
      rethrow;
    }
  }
}
