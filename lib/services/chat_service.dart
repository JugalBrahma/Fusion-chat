import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../config/api_config.dart';

class ChatService {
  static const String baseUrl = ApiConfig.baseUrl;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Message> sendMessage(String message, {String? folderId}) async {
    try {
      // Get current user's Firebase token
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final idToken = await user.getIdToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl/agent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'query': message,
          if (folderId != null) 'folder_id': folderId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final payload = responseData['response'];
        final fromDocuments = responseData['from_documents'] as bool? ?? false;
        final docCount = responseData['doc_reference_count'] as int? ?? 0;

        if (payload is Map<String, dynamic>) {
          final answer = payload['answer']?.toString() ?? '';
          final mcqFlag = payload['mcq_is_true'] as bool? ?? false;
          final mcqList = (payload['mcqs'] as List?)
                  ?.map((e) => Mcq.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList() ??
              const [];

          final message = Message.text(
            answer,
            mcqIsTrue: mcqFlag || mcqList.isNotEmpty,
            mcqs: mcqList,
            processing_time: payload['processing_time']?.toString(),
            fromDocuments: fromDocuments,
            docReferenceCount: docCount,
          );

          return message;
        }

        final responseText = payload ?? responseData['error'] ?? 'No response';
        return Message.text(responseText.toString());
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to agent: $e');
    }
  }

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
  Future<void> sendChatMessage(String folderId, String userMessage) async {
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
      final agentResponse = await sendMessage(userMessage, folderId: folderId);

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
