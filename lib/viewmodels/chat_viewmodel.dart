import '../../data/services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatState {
  final bool isSending;

  const ChatState({this.isSending = false});

  ChatState copyWith({bool? isSending}) {
    return ChatState(isSending: isSending ?? this.isSending);
  }
}

class ChatViewModel extends StateNotifier<ChatState> {
  ChatViewModel(this._chatService) : super(const ChatState());

  final ChatService _chatService;

  Stream<QuerySnapshot> messagesStream(String folderId) {
    return _chatService.getMessagesStream(folderId);
  }

  Future<void> sendMessage(String folderId, String userMessage) async {
    if (state.isSending) return;
    state = state.copyWith(isSending: true);
    try {
      await _chatService.sendChatMessage(folderId, userMessage);
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  Future<void> clearChat(String folderId) async {
    await _chatService.clearChat(folderId);
  }
}

final chatProvider = StateNotifierProvider<ChatViewModel, ChatState>((ref) {
  return ChatViewModel(ChatService());
});
