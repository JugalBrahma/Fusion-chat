import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';

class PdfDeleteService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String baseUrl = ApiConfig.baseUrl;

  Future<void> deletePdf(String pdfId, {String? folderId}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final token = await user.getIdToken();

    final request = http.Request("DELETE", Uri.parse("$baseUrl/pdf/$pdfId"));
    request.headers["Authorization"] = "Bearer $token";
    
    if (folderId != null) {
      request.headers["folder_id"] = folderId;
    }

    final response = await request.send();

    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      final errorBody = responseBody.isNotEmpty ? jsonDecode(responseBody) : null;
      throw Exception("Failed to delete PDF: ${errorBody?['detail'] ?? 'Unknown error'}");
    }
  }
}
