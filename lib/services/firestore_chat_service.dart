import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_service.dart';

class FirestoreChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatService _chatService = ChatService();

  /// Get messages stream for a specific folder
  Stream<QuerySnapshot> getMessagesStream(String folderId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('folders')
        .doc(folderId)
        .collection('chats')
        .doc('main_chat')
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Send a message and get agent response (conversation is handled by backend)
  Future<void> sendMessage(String folderId, String userMessage) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final chatRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('folders')
        .doc(folderId)
        .collection('chats')
        .doc('main_chat')
        .collection('messages');

    try {
      // Add user message to Firestore (for UI display)
      await chatRef.add({
        'text': userMessage,
        'isUser': true,
        'timestamp': FieldValue.serverTimestamp(),
        'role': 'user',
      });

      // Get agent response (conversation history is handled by backend RAG agent)
      final agentResponse = await _chatService.sendMessage(userMessage, folderId: folderId);

      // Prepare MCQ data as a list
      final mcqEntries = agentResponse.mcqs.map((mcq) => mcq.toJson()).toList();

      // Add agent response to Firestore (for UI display)
      await chatRef.add({
        'text': agentResponse.text ?? '',
        'isUser': false,
        'timestamp': FieldValue.serverTimestamp(),
        'role': 'assistant',
        'processing_time': agentResponse.processing_time,
        'mcq_is_true': agentResponse.mcqIsTrue || mcqEntries.isNotEmpty,
        'mcqs': mcqEntries, // This stores the MCQs as a list in Firestore
        'from_documents': agentResponse.fromDocuments,
        'doc_reference_count': agentResponse.docReferenceCount,
      });
    } catch (e) {
      // Add error message to Firestore
      await chatRef.add({
        'text': 'Error: $e',
        'isUser': false,
        'timestamp': FieldValue.serverTimestamp(),
        'role': 'error',
      });
      rethrow;
    }
  }

  /// Clear all messages for a folder
  Future<void> clearChat(String folderId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final messagesRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('folders')
        .doc(folderId)
        .collection('chats')
        .doc('main_chat')
        .collection('messages');

    final batch = _firestore.batch();
    final snapshot = await messagesRef.get();
    
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
}
