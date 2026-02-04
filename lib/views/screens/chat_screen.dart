import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/message.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/mcq_selection_viewmodel.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String folderId;
  final String folderName;

  const ChatScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Widget _buildHighlightedText(String text, BuildContext context) {
    final regex = RegExp(r'<doc>(.*?)</doc>');
    final matches = regex.allMatches(text);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF374151);
    
    if (matches.isEmpty) {
      return Text(
        _addEmojisToContent(text),
        style: GoogleFonts.inter(
          fontSize: 15,
          color: textColor,
          height: 1.6,
          fontWeight: FontWeight.w400,
        ),
      );
    }
    
    final List<TextSpan> spans = [];
    int lastEnd = 0;
    
    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: _addEmojisToContent(text.substring(lastEnd, match.start)),
          style: GoogleFonts.inter(
            fontSize: 15,
            color: textColor,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ));
      }
      
      spans.add(TextSpan(
        text: _addEmojisToContent(match.group(1)!),
        style: GoogleFonts.inter(
          fontSize: 15,
          color: const Color(0xFF2563EB),
          height: 1.6,
          fontWeight: FontWeight.w600,
        ),
      ));
      
      lastEnd = match.end;
    }
    
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: _addEmojisToContent(text.substring(lastEnd)),
        style: GoogleFonts.inter(
          fontSize: 15,
          color: textColor,
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
    final chatState = ref.read(chatProvider);
    if (_messageController.text.trim().isEmpty || chatState.isSending) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    try {
      await ref.read(chatProvider.notifier).sendMessage(widget.folderId, userMessage);
    } catch (e, stack) {
      debugPrint('Chat send failed: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not send your message. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: StreamBuilder<QuerySnapshot>(
                stream: ref.watch(chatProvider.notifier).messagesStream(widget.folderId),
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
                    reverse: true,
                    itemBuilder: (context, index) {
                      final doc = messages[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final isUser = data['isUser'] ?? false;
                      final role = data['role'] ?? 'unknown';
                      
                      final message = Message.fromJson(data);
                      
                      return _buildMessageContent(
                        message,
                        isUser,
                        role,
                        doc.id,
                      );
                    },
                  );
                },
              ),
            ),
          ),
          _buildMessageInput(chatState.isSending),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.headlineMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask questions about your documents',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(
    Message message,
    bool isUser,
    String role,
    String messageId,
  ) {
    if (isUser) {
      return _buildMessageBubble(message.text ?? '', isUser, role);
    }
    
    if (message.mcqIsTrue && message.mcqs.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(message.mcqs.length, (index) {
            return _buildMcqCard(messageId, message.mcqs[index], index);
          }),
        ],
      );
    }
    
    final hasDocumentContext = message.fromDocuments ||
        message.docReferenceCount > 0 ||
        ((message.text ?? '').contains('<doc>') && (message.text ?? '').contains('</doc>'));
    
    return _buildMessageBubble(
      message.text ?? '', 
      isUser, 
      role, 
      hasDocumentContext: hasDocumentContext,
      docCount: message.docReferenceCount,
    );
  }

  Widget _buildMcqCard(String messageId, Mcq mcq, int mcqIndex) {
    final selectionMap = ref.watch(mcqSelectionProvider);
    final selectedLetter = selectionMap['$messageId/$mcqIndex'];

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
                color: Theme.of(context).cardTheme.color ?? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(mcq.options.length, (index) {
                    final option = mcq.options[index];
                    final optionLetter = String.fromCharCode(65 + index);
                    final isSelected = selectedLetter == optionLetter;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ref
                                .read(mcqSelectionProvider.notifier)
                                .selectOption(messageId, mcqIndex, optionLetter);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).cardTheme.color ?? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white),
                            foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
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
                                      color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
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
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  if (selectedLetter != null) ...[
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final selectedIndex = selectedLetter.codeUnitAt(0) - 65;
                        final selectedOptionText = mcq.options[selectedIndex];
                        
                        String correctAnswer = mcq.answer.trim();
                        bool isCorrect;
                        String correctAnswerText;
                        
                        final letterMatch = RegExp(r'[()\s]*([ABCDabcd])[).\s]*', caseSensitive: false).firstMatch(correctAnswer);
                        
                        if (letterMatch != null) {
                          String answerLetter = letterMatch.group(1)!.toUpperCase();
                          isCorrect = selectedLetter == answerLetter;
                          int correctIndex = answerLetter.codeUnitAt(0) - 65;
                          correctAnswerText = mcq.options[correctIndex];
                        } else if (correctAnswer.length == 1 && RegExp(r'^[ABCD]$').hasMatch(correctAnswer)) {
                          isCorrect = selectedLetter == correctAnswer;
                          int correctIndex = correctAnswer.codeUnitAt(0) - 65;
                          correctAnswerText = mcq.options[correctIndex];
                        } else {
                          isCorrect = selectedOptionText.trim() == correctAnswer;
                          correctAnswerText = correctAnswer;
                        }
                        
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCorrect 
                                ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
                                : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2)),
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
                                        ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46))
                                        : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B)),
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
                    color: Colors.black.withValues(alpha: 0.15),
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
            const SizedBox(width: 42),
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
                    color: isUser ? null : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white),
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
                    boxShadow: isUser ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasDocumentContext && !isUser) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? const Color(0xFF374151) 
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            ' From Your Documents${docCount > 0 ? ' ($docCount references)' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
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
                            color: isUser ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
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
                              : _buildHighlightedText(content, context),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isUser ? 'You' : role == 'error' ? 'Error' : 'Assistant',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 42),
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
      return ' $title';
    } else if (lowerTitle.contains('answer') || lowerTitle.contains('solution')) {
      return ' $title';
    } else if (lowerTitle.contains('summary') || lowerTitle.contains('overview')) {
      return ' $title';
    } else if (lowerTitle.contains('important') || lowerTitle.contains('note')) {
      return ' $title';
    } else if (lowerTitle.contains('example')) {
      return ' $title';
    } else if (lowerTitle.contains('warning') || lowerTitle.contains('error')) {
      return ' $title';
    } else if (lowerTitle.contains('definition')) {
      return ' $title';
    } else if (lowerTitle.contains('step')) {
      return ' $title';
    } else if (lowerTitle.contains('fact')) {
      return ' $title';
    }
    
    return title;
  }

  String _addEmojisToContent(String content) {
    final lines = content.split('\n');
    final processedLines = <String>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      
      if (trimmed.startsWith('•') || trimmed.startsWith('-') || trimmed.startsWith('*')) {
        processedLines.add(line.replaceFirst(RegExp(r'^[•\-\*]\s*'), '=> '));
      } else if (RegExp(r'^\d+\.\s*').hasMatch(trimmed)) {
        processedLines.add(line.replaceFirst(RegExp(r'^\d+\.\s*'), '- '));
      } else if (trimmed.toLowerCase().contains('important')) {
        processedLines.add(line.replaceAll('important', ' important'));
      } else if (trimmed.toLowerCase().contains('note')) {
        processedLines.add(line.replaceAll('note', ' note'));
      } else {
        processedLines.add(line);
      }
    }
    
    return processedLines.join('\n');
  }

  Widget _buildMessageInput(bool isSending) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final darkGrey = const Color(0xFF2A2A2E);
    final borderColor = isDark ? darkGrey : Colors.black.withValues(alpha: 0.08);
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black87);

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.all(0),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? darkGrey : const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    fillColor: isDark ? darkGrey : const Color(0xFFF5F5F7),
                    hintText: 'Ask anything (Ctrl+L)',
                    hintStyle: GoogleFonts.inter(
                      color: textColor.withValues(alpha: 0.5),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: textColor,
                  ),
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              if (isSending)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
              else
                Material(
                  color: theme.colorScheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _sendMessage,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
