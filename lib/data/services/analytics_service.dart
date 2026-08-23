import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/analytics_data.dart';

class AnalyticsService {
  static const String baseUrl = ApiConfig.baseUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<AnalyticsData> getAnalytics({String? folderId}) async {
    try {
      final user = _auth.currentUser;
      String? idToken;
      if (user != null) {
        idToken = await user.getIdToken();
      }

      final url = folderId != null && folderId.isNotEmpty
          ? '$baseUrl/api/analytics/$folderId'
          : '$baseUrl/api/analytics';

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (idToken != null) {
        headers['Authorization'] = 'Bearer $idToken';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return AnalyticsData.fromJson(data);
      } else {
        throw Exception('Failed to load analytics: ${response.statusCode}');
      }
    } catch (e) {
      // Return empty/fallback data on failure
      return AnalyticsData.empty();
    }
  }
}
