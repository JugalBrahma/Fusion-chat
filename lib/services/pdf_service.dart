import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';

class PdfService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _baseUrl;

  PdfService({FirebaseFirestore? firestore, FirebaseAuth? auth, String? baseUrl})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserPdfs() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Not logged in');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('pdfs')
        .orderBy('uploaded_at', descending: true)
        .snapshots();
  }

  Stream<int> pdfCountStream(String folderId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('folders')
        .doc(folderId)
        .collection('pdfs')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<Map<String, dynamic>> uploadPdf(File file, {String? folderId}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final token = await user.getIdToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/upload-pdf'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    if (folderId != null) {
      request.headers['folder_id'] = folderId;
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType('application', 'pdf'),
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Upload failed: ${response.statusCode}');
    }

    final responseData = jsonDecode(responseBody);

    return {
      'success': true,
      'data': responseData,
      'error': null,
    };
  }

  Future<void> deletePdf(String pdfId, {String? folderId}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final token = await user.getIdToken();

    final request = http.Request('DELETE', Uri.parse('$_baseUrl/pdf/$pdfId'));
    request.headers['Authorization'] = 'Bearer $token';

    if (folderId != null) {
      request.headers['folder_id'] = folderId;
    }

    final response = await request.send();

    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      final errorBody = responseBody.isNotEmpty ? jsonDecode(responseBody) : null;
      throw Exception(
        "Failed to delete PDF: ${errorBody?['detail'] ?? 'Unknown error'}",
      );
    }
  }
}
