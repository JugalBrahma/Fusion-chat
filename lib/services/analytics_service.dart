import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getFolderAnalytics(String folderId) async {
    try {
      // Get all messages in the folder
      final messagesRef = _firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('folders')
          .doc(folderId)
          .collection('chats')
          .doc('main_chat')
          .collection('messages');
      
      final messagesSnapshot = await messagesRef.get();
      final messages = messagesSnapshot.docs;
      
      // Calculate analytics
      int totalQuestions = 0;
      int mcqCount = 0;
      int mcqCorrect = 0;
      Map<String, int> topicCounts = {};
      Map<String, int> difficultyProgress = {'Easy': 0, 'Medium': 0, 'Hard': 0};
      List<Map<String, dynamic>> practiceHistory = [];
      
      // Track daily activity for streak calculation
      Map<String, int> dailyActivity = {};
      
      for (var doc in messages) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        final isUser = data['isUser'] as bool? ?? false;
        final mcqIsTrue = data['mcqIsTrue'] as bool? ?? false;
        final mcqs = data['mcqs'] as List? ?? [];
        final text = data['text'] as String? ?? '';
        
        if (timestamp != null) {
          final date = timestamp.toDate();
          final dateKey = '${date.year}-${date.month}-${date.day}';
          dailyActivity[dateKey] = (dailyActivity[dateKey] ?? 0) + 1;
        }
        
        // Count MCQs
        if (!isUser && mcqIsTrue && mcqs.isNotEmpty) {
          mcqCount += mcqs.length;
          
          // For demo purposes, we'll assume some MCQs are answered
          // In a real app, you'd track actual user selections
          mcqCorrect = (mcqCorrect * 0.85).round(); // Simulate 85% accuracy
        }
        
        // Analyze text for topics and difficulty
        if (!isUser && text.isNotEmpty) {
          totalQuestions++;
          
          // Simple topic detection (you can make this more sophisticated)
          if (text.toLowerCase().contains('physics')) {
            topicCounts['Physics'] = (topicCounts['Physics'] ?? 0) + 1;
          } else if (text.toLowerCase().contains('chemistry')) {
            topicCounts['Chemistry'] = (topicCounts['Chemistry'] ?? 0) + 1;
          } else if (text.toLowerCase().contains('biology')) {
            topicCounts['Biology'] = (topicCounts['Biology'] ?? 0) + 1;
          } else if (text.toLowerCase().contains('math')) {
            topicCounts['Mathematics'] = (topicCounts['Mathematics'] ?? 0) + 1;
          } else {
            topicCounts['General'] = (topicCounts['General'] ?? 0) + 1;
          }
          
          // Simple difficulty detection based on keywords
          if (text.toLowerCase().contains('advanced') || text.toLowerCase().contains('complex')) {
            difficultyProgress['Hard'] = (difficultyProgress['Hard'] ?? 0) + 1;
          } else if (text.toLowerCase().contains('intermediate') || text.toLowerCase().contains('moderate')) {
            difficultyProgress['Medium'] = (difficultyProgress['Medium'] ?? 0) + 1;
          } else {
            difficultyProgress['Easy'] = (difficultyProgress['Easy'] ?? 0) + 1;
          }
        }
      }
      
      // Calculate streak
      final streak = _calculateStreak(dailyActivity);
      
      // Create practice history (last 5 sessions)
      final sortedDates = dailyActivity.keys.toList()..sort();
      for (int i = sortedDates.length - 1; i >= 0 && i >= sortedDates.length - 5; i--) {
        final date = DateTime.parse(sortedDates[i]);
        final topic = topicCounts.keys.isNotEmpty ? topicCounts.keys.first : 'General';
        practiceHistory.add({
          'title': '$topic - Practice Session',
          'subtitle': '${dailyActivity[sortedDates[i]]} messages · ${_getTimeAgo(date)}',
          'score': 0.75 + (0.2 * (i / 5)), // Simulate varying scores
          'accent': _getTopicColor(topic),
        });
      }
      
      // Calculate focus segments (based on topic distribution)
      final totalTopics = topicCounts.values.fold(0, (a, b) => a + b);
      List<Map<String, dynamic>> segments = [];
      
      topicCounts.forEach((topic, count) {
        if (totalTopics > 0) {
          segments.add({
            'label': topic,
            'value': (count / totalTopics) * 100,
            'color': _getTopicColor(topic),
          });
        }
      });
      
      // Sort segments by value
      segments.sort((a, b) => b['value'].compareTo(a['value']));
      
      // Calculate accuracy
      final accuracy = totalQuestions > 0 ? (mcqCorrect / mcqCount) : 0.0;
      
      return {
        'segments': segments,
        'quickStats': {
          'questionsPracticed': totalQuestions,
          'avgAccuracy': (accuracy * 100).round(),
          'streak': streak,
          'foldersSynced': 1, // Current folder
        },
        'history': practiceHistory,
        'progress': [
          {
            'label': 'Hard',
            'value': difficultyProgress['Hard']! > 0 
                ? difficultyProgress['Hard']! / (difficultyProgress['Easy']! + difficultyProgress['Medium']! + difficultyProgress['Hard']!)
                : 0.0,
            'color': const Color(0xFF7C3BED),
          },
          {
            'label': 'Medium',
            'value': difficultyProgress['Medium']! > 0
                ? difficultyProgress['Medium']! / (difficultyProgress['Easy']! + difficultyProgress['Medium']! + difficultyProgress['Hard']!)
                : 0.0,
            'color': const Color(0xFF00D6C4),
          },
          {
            'label': 'Easy',
            'value': difficultyProgress['Easy']! > 0
                ? difficultyProgress['Easy']! / (difficultyProgress['Easy']! + difficultyProgress['Medium']! + difficultyProgress['Hard']!)
                : 0.0,
            'color': const Color(0xFFE7B008),
          },
        ],
      };
    } catch (e) {
      print('Error fetching analytics: $e');
      return _getDefaultAnalytics();
    }
  }
  
  int _calculateStreak(Map<String, int> dailyActivity) {
    if (dailyActivity.isEmpty) return 0;
    
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayKey = '${yesterday.year}-${yesterday.month}-${yesterday.day}';
    
    int streak = 0;
    
    // Check if there's activity today or yesterday
    if (dailyActivity.containsKey(todayKey) || dailyActivity.containsKey(yesterdayKey)) {
      streak = 1;
      
      // Count consecutive days
      DateTime checkDate = dailyActivity.containsKey(todayKey) ? today : yesterday;
      
      while (true) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        final checkKey = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
        
        if (dailyActivity.containsKey(checkKey)) {
          streak++;
        } else {
          break;
        }
      }
    }
    
    return streak;
  }
  
  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }
  
  Color _getTopicColor(String topic) {
    switch (topic.toLowerCase()) {
      case 'physics':
        return const Color(0xFF7C3BED);
      case 'chemistry':
        return const Color(0xFF00D6C4);
      case 'biology':
        return const Color(0xFFE7B008);
      case 'mathematics':
        return const Color(0xFFAB30E8);
      default:
        return const Color(0xFF3B82F6);
    }
  }
  
  Map<String, dynamic> _getDefaultAnalytics() {
    return {
      'segments': [
        {'label': 'Concept Clarity', 'value': 42.0, 'color': const Color(0xFF3B82F6)},
        {'label': 'Speed', 'value': 30.0, 'color': const Color(0xFF22C55E)},
        {'label': 'Accuracy', 'value': 18.0, 'color': const Color(0xFFF97316)},
        {'label': 'Revision', 'value': 10.0, 'color': const Color(0xFF6366F1)},
      ],
      'quickStats': {
        'questionsPracticed': 0,
        'avgAccuracy': 0,
        'streak': 0,
        'foldersSynced': 0,
      },
      'history': <Map<String, dynamic>>[],
      'progress': [
        {'label': 'Hard', 'value': 0.0, 'color': const Color(0xFF7C3BED)},
        {'label': 'Medium', 'value': 0.0, 'color': const Color(0xFF00D6C4)},
        {'label': 'Easy', 'value': 0.0, 'color': const Color(0xFFE7B008)},
      ],
    };
  }
}
