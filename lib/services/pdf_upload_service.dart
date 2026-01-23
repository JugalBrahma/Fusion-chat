import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';

class PdfUploadService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>> uploadPdf(File file, {String? folderId}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final token = await user.getIdToken();

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/upload-pdf"),
    );

    request.headers["Authorization"] = "Bearer $token";
    
    if (folderId != null) {
      request.headers["folder_id"] = folderId;
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        file.path,
        contentType: MediaType("application", "pdf"),
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception("Upload failed: ${response.statusCode}");
    }

    // Parse JSON response to get metadata
    final responseData = jsonDecode(responseBody);

    return {
      "success": true,
      "data": responseData,
      "error": null
    };
  }
}
