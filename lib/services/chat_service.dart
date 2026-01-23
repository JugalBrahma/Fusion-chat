import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/message.dart';
import '../config/api_config.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  static const String baseUrl = ApiConfig.baseUrl;
  
  Future<Message> sendMessage(String message, {String? folderId}) async {
    try {
      // Get current user's Firebase token
      final user = FirebaseAuth.instance.currentUser;
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
}
