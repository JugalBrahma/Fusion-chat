import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../../config/api_config.dart';

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

          Map<String, dynamic>? _stringMap(Map<String, dynamic>? map) {
            return map == null
                ? null
                : map.map((key, value) => MapEntry(key.toString(), value));
          }

          int? _parseInt(dynamic value) {
            if (value is int) return value;
            if (value is num) return value.toInt();
            if (value is String) return int.tryParse(value);
            return null;
          }

          // DEBUG: Log the payload structure
          print('DEBUG: payload keys = ${payload.keys.toList()}');
          print('DEBUG: payload[usage] = ${payload['usage']}');

          final usage = _stringMap(
              (payload['usage'] as Map?)?.map((key, value) => MapEntry(key.toString(), value))
                  as Map<String, dynamic>?);
          
          // Try to get totals from multiple possible locations
          Map<String, dynamic>? usageTotals;
          
          // First try usage['totals']
          if (usage != null && usage['totals'] is Map) {
            usageTotals = _stringMap((usage['totals'] as Map).map((k, v) => MapEntry(k.toString(), v)));
          }
          
          // If no totals, try to extract from usage['answer'] or usage['mcq_detection']
          if (usageTotals == null && usage != null) {
            final answerUsage = usage['answer'] is Map ? usage['answer'] as Map : null;
            final mcqUsage = usage['mcq_detection'] is Map ? usage['mcq_detection'] as Map : null;
            
            // Merge answer and mcq usage
            if (answerUsage != null || mcqUsage != null) {
              final totals = <String, int>{};
              
              void addTokens(String key, dynamic value) {
                if (value is int) {
                  totals[key] = (totals[key] ?? 0) + value;
                } else if (value is num) {
                  totals[key] = (totals[key] ?? 0) + value.toInt();
                }
              }
              
              if (answerUsage != null) {
                addTokens('prompt_tokens', answerUsage['prompt_tokens']);
                addTokens('completion_tokens', answerUsage['completion_tokens']);
                addTokens('total_tokens', answerUsage['total_tokens']);
              }
              
              if (mcqUsage != null) {
                addTokens('prompt_tokens', mcqUsage['prompt_tokens']);
                addTokens('completion_tokens', mcqUsage['completion_tokens']);
                addTokens('total_tokens', mcqUsage['total_tokens']);
              }
              
              if (totals.isNotEmpty) {
                usageTotals = totals;
              }
            }
          }
          
          print('DEBUG: usage = $usage');
          print('DEBUG: usageTotals = $usageTotals');

          final message = Message.text(
            answer,
            mcqIsTrue: mcqFlag || mcqList.isNotEmpty,
            mcqs: mcqList,
            processing_time: payload['processing_time']?.toString(),
            fromDocuments: fromDocuments,
            docReferenceCount: docCount,
            usage: usage,
            promptTokens: _parseInt(usageTotals?['prompt_tokens']),
            completionTokens: _parseInt(usageTotals?['completion_tokens']),
            totalTokens: _parseInt(usageTotals?['total_tokens']),
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
        'mcqs': mcqEntries,
        'from_documents': agentResponse.fromDocuments,
        'doc_reference_count': agentResponse.docReferenceCount,
        if (agentResponse.usage != null) 'usage': agentResponse.usage,
        if (agentResponse.promptTokens != null)
          'prompt_tokens': agentResponse.promptTokens,
        if (agentResponse.completionTokens != null)
          'completion_tokens': agentResponse.completionTokens,
        if (agentResponse.totalTokens != null)
          'total_tokens': agentResponse.totalTokens,
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
