import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class FolderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _baseUrl = ApiConfig.baseUrl;

  // Create a new folder
  Future<void> createFolder(String folderName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('folders')
        .add({
          'name': folderName,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  // Get a stream of all folders for the current user
  Stream<QuerySnapshot> getFolders() {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('folders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Delete a folder using the secure backend endpoint (checks for PDFs)
  Future<void> deleteFolder(String folderId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final token = await user.getIdToken();

    final response = await http.delete(
      Uri.parse("$_baseUrl/api/folders/$folderId"),
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
