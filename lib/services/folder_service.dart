import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'folder_delete_service.dart';

class FolderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FolderDeleteService _folderDeleteService = FolderDeleteService();

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
    await _folderDeleteService.deleteFolder(folderId);
  }
}
