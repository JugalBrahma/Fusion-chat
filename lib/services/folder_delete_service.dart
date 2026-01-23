import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';

class FolderDeleteService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String baseUrl = ApiConfig.baseUrl;

  Future<void> deleteFolder(String folderId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final token = await user.getIdToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/api/folders/$folderId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      throw Exception("Failed to delete folder: ${errorBody?['detail'] ?? 'Unknown error'}");
    }
  }
}
