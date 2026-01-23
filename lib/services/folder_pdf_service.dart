import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FolderPdfService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FolderPdfService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

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
}
