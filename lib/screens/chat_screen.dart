import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_chat_service.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final String folderId;
  final String folderName;

  const ChatScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirestoreChatService _chatService = FirestoreChatService();
  bool _isLoading = false;
  Map<int, String?> _selectedOptions = {}; // Track selected option for each MCQ

  // Helper function to render text with <doc> tags in blue
  Widget _buildHighlightedText(String text) {
    final regex = RegExp(r'<doc>(.*?)</doc>');
    final matches = regex.allMatches(text);
    
    if (matches.isEmpty) {
      return Text(
        _addEmojisToContent(text),
        style: GoogleFonts.inter(
          fontSize: 15,
          color: const Color(0xFF374151),
          height: 1.6,
          fontWeight: FontWeight.w400,
        ),
      );
    }
    
    final List<TextSpan> spans = [];
    int lastEnd = 0;
    
    for (final match in matches) {
      // Add text before the <doc> tag
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: _addEmojisToContent(text.substring(lastEnd, match.start)),
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF374151),
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ));
      }
      
      // Add the highlighted text inside <doc> tags
      spans.add(TextSpan(
        text: _addEmojisToContent(match.group(1)!),
        style: GoogleFonts.inter(
          fontSize: 15,
          color: const Color(0xFF2563EB), // Blue color for document text
          height: 1.6,
          fontWeight: FontWeight.w600, // Slightly bolder for emphasis
          backgroundColor: const Color(0xFFEFF6FF), // Light blue background
        ),
      ));
      
      lastEnd = match.end;
    }
    
    // Add remaining text after the last </doc> tag
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: _addEmojisToContent(text.substring(lastEnd)),
        style: GoogleFonts.inter(
          fontSize: 15,
          color: const Color(0xFF374151),
          height: 1.6,
          fontWeight: FontWeight.w400,
        ),
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isLoading = true;
    });

    try {
      await _chatService.sendMessage(widget.folderId, userMessage);
    } catch (e) {
      // Error is already stored in Firestore, just show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatService.getMessagesStream(widget.folderId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3B82F6),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                          SizedBox(height: 16),
                          Text(
                            'Error loading messages',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final messages = snapshot.data?.docs ?? [];

                  if (messages.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    reverse: true, // Show newest messages at bottom
                    itemBuilder: (context, index) {
                      final doc = messages[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final isUser = data['isUser'] ?? false;
                      final role = data['role'] ?? 'unknown';
                      
                      // Parse into Message model to get MCQ data
                      final message = Message.fromJson(data);
                      
                      return _buildMessageContent(message, isUser, role);
                    },
                  );
                },
              ),
            ),
          ),
          
          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask questions about your documents',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(Message message, bool isUser, String role) {
    // For user messages, always show as text bubble
    if (isUser) {
      return _buildMessageBubble(message.text ?? '', isUser, role);
    }
    
    // For assistant messages, check if MCQ is present
    if (message.mcqIsTrue && message.mcqs.isNotEmpty) {
      // Show only MCQ cards when MCQs are present
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show all MCQ cards
          ...List.generate(message.mcqs.length, (index) {
            return _buildMcqCard(message.mcqs[index], index);
          }),
        ],
      );
    }
    
    // Regular text message - use backend flag, fallback to <doc> tag detection
    final hasDocumentContext = message.fromDocuments ||
        message.docReferenceCount > 0 ||
        ((message.text ?? '').contains('<doc>') && (message.text ?? '').contains('</doc>'));
    
    // Regular text message (or when no MCQs)
    return _buildMessageBubble(
      message.text ?? '', 
      isUser, 
      role, 
      hasDocumentContext: hasDocumentContext,
      docCount: message.docReferenceCount,
    );
  }

  
  Widget _buildMcqCard(Mcq mcq, int mcqIndex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.quiz,
              size: 20,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Multiple Choice Question ${mcqIndex + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    mcq.question,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(mcq.options.length, (index) {
                    final option = mcq.options[index];
                    final optionLetter = String.fromCharCode(65 + index); // A, B, C, D
                    final isSelected = _selectedOptions[mcqIndex] == optionLetter;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedOptions[mcqIndex] = optionLetter;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1E293B),
                            elevation: 1,
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    optionLetter,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  // Show answer below when an option is selected
                  if (_selectedOptions[mcqIndex] != null) ...[
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        // Find the index of the selected option
                        final selectedLetter = _selectedOptions[mcqIndex]!;
                        final selectedIndex = selectedLetter.codeUnitAt(0) - 65; // Convert A,B,C,D to 0,1,2,3
                        final selectedOptionText = mcq.options[selectedIndex];
                        
                        // Check if answer is a letter (A, B, C, D) or full text
                        String correctAnswer = mcq.answer.trim();
                        bool isCorrect;
                        String correctAnswerText;
                        
                        // Check for patterns like "(b)", "b)", "(B)", "B." etc.
                        final letterMatch = RegExp(r'[()\s]*([ABCDabcd])[).\s]*', caseSensitive: false).firstMatch(correctAnswer);
                        
                        if (letterMatch != null) {
                          // Answer is a letter (with or without formatting), compare with selected letter
                          String answerLetter = letterMatch.group(1)!.toUpperCase();
                          isCorrect = selectedLetter == answerLetter;
                          // Get the full text for the correct answer
                          int correctIndex = answerLetter.codeUnitAt(0) - 65;
                          correctAnswerText = mcq.options[correctIndex];
                        } else if (correctAnswer.length == 1 && RegExp(r'^[ABCD]$').hasMatch(correctAnswer)) {
                          // Answer is a plain letter
                          isCorrect = selectedLetter == correctAnswer;
                          int correctIndex = correctAnswer.codeUnitAt(0) - 65;
                          correctAnswerText = mcq.options[correctIndex];
                        } else {
                          // Answer is full text, compare with selected option text
                          isCorrect = selectedOptionText.trim() == correctAnswer;
                          correctAnswerText = correctAnswer;
                        }
                        
                        // Debug logging
                        print('MCQ Debug:');
                        print('Selected letter: $selectedLetter');
                        print('Selected index: $selectedIndex');
                        print('Selected option: "$selectedOptionText"');
                        print('Correct answer: "${mcq.answer}"');
                        print('Is correct: $isCorrect');
                        
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCorrect 
                                ? const Color(0xFFD1FAE5) 
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCorrect 
                                  ? const Color(0xFF10B981) 
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCorrect 
                                    ? Icons.check_circle 
                                    : Icons.cancel,
                                color: isCorrect 
                                    ? const Color(0xFF10B981) 
                                    : const Color(0xFFEF4444),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isCorrect 
                                      ? '✓ Correct! Well done.'
                                      : '✗ Incorrect. The correct answer is: ${correctAnswerText}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isCorrect 
                                        ? const Color(0xFF065F46) 
                                        : const Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String messageText, bool isUser, String role, {bool hasDocumentContext = false, int docCount = 0}) {
    // Detect if message contains a title (ends with colon or is a short question)
    final lines = messageText.split('\n');
    String? title;
    String content = messageText;
    
    if (lines.isNotEmpty && (lines[0].endsWith(':') || lines[0].endsWith('?') || (lines[0].length < 50 && !lines[0].contains('.')))) {
      title = lines[0];
      content = lines.skip(1).join('\n').trim();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: role == 'error' 
                    ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])
                    : hasDocumentContext
                        ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)])
                        : const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                role == 'error' ? Icons.error_outline : 
                hasDocumentContext ? Icons.auto_stories : Icons.psychology,
                size: 22,
                color: Colors.white,
              ),
            ),
          ] else ...[
            const SizedBox(width: 42), // Spacer for user messages
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser ? null : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: isUser
                        ? null
                        : Border.all(
                            color: role == 'error' 
                                ? const Color(0xFFEF4444)
                                : hasDocumentContext 
                                    ? const Color(0xFF8B5CF6)
                                    : const Color(0xFFE2E8F0), 
                            width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                      if (!isUser)
                        BoxShadow(
                          color: role == 'error' 
                              ? const Color(0xFFEF4444).withOpacity(0.1)
                              : hasDocumentContext 
                                  ? const Color(0xFF8B5CF6).withOpacity(0.1)
                                  : const Color(0xFF3B82F6).withOpacity(0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasDocumentContext && !isUser) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '📚 From Your Documents${docCount > 0 ? ' ($docCount references)' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF4B5563),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (title != null) ...[
                        Text(
                          _addEmojisToTitle(title),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: isUser ? Colors.white : const Color(0xFF1F2937),
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (content.isNotEmpty) const SizedBox(height: 12),
                      ],
                      if (content.isNotEmpty)
                        Container(
                          padding: EdgeInsets.only(top: title != null ? 12 : 0),
                          child: isUser 
                              ? Text(
                                  _addEmojisToContent(content),
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    color: Colors.white,
                                    height: 1.6,
                                    fontWeight: FontWeight.w400,
                                  ),
                                )
                              : _buildHighlightedText(content),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isUser ? 'You' : role == 'error' ? 'Error' : 'Assistant',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 42), // Spacer for user messages
          ] else ...[
            const SizedBox(width: 42),
          ],
        ],
      ),
    );
  }

  String _addEmojisToTitle(String title) {
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('question') || lowerTitle.contains('?')) {
      return '🤔 $title';
    } else if (lowerTitle.contains('answer') || lowerTitle.contains('solution')) {
      return '✅ $title';
    } else if (lowerTitle.contains('summary') || lowerTitle.contains('overview')) {
      return '📝 $title';
    } else if (lowerTitle.contains('important') || lowerTitle.contains('note')) {
      return '⭐ $title';
    } else if (lowerTitle.contains('example')) {
      return '💡 $title';
    } else if (lowerTitle.contains('warning') || lowerTitle.contains('error')) {
      return '⚠️ $title';
    } else if (lowerTitle.contains('definition')) {
      return '📖 $title';
    } else if (lowerTitle.contains('step')) {
      return '🔢 $title';
    } else if (lowerTitle.contains('fact')) {
      return '🎯 $title';
    }
    
    return title;
  }

  String _addEmojisToContent(String content) {
    // Add emojis to bullet points and numbered lists
    final lines = content.split('\n');
    final processedLines = <String>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      
      if (trimmed.startsWith('•') || trimmed.startsWith('-') || trimmed.startsWith('*')) {
        processedLines.add(line.replaceFirst(RegExp(r'^[•\-\*]\s*'), '=> '));
      } else if (RegExp(r'^\d+\.\s*').hasMatch(trimmed)) {
        processedLines.add(line.replaceFirst(RegExp(r'^\d+\.\s*'), '🔹 '));
      } else if (trimmed.toLowerCase().contains('important')) {
        processedLines.add(line.replaceAll('important', '⭐ important'));
      } else if (trimmed.toLowerCase().contains('note')) {
        processedLines.add(line.replaceAll('note', '📝 note'));
      } else {
        processedLines.add(line);
      }
    }
    
    return processedLines.join('\n');
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask about your documents...',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isLoading ? null : _sendMessage,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
