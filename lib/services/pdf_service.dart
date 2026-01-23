import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PdfService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PdfService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

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
}
