import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class UserConnect {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> getUserIdToken() async {
    final user = _auth.currentUser;
    return user != null ? await user.getIdToken() : null;
  }

  Future<Map<String, dynamic>> createFolder(String folderName) async {
    final token = await getUserIdToken();
    if (token == null) {
      throw Exception("User not authenticated");
    }
    
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/folders"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "folder_name": folderName,  // Changed to match the expected request body
      }),
    );
    if (response.statusCode == 200) {
      print(token);
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to create folder: ${response.body}");
    }
  }
}
