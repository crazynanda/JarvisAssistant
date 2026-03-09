import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/chat_history_service.dart';
import '../models/message_model.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final ChatHistoryService _chatHistory = ChatHistoryService();
  List<MessageModel> _allMessages = [];
  Map<String, List<MessageModel>> _groupedMessages = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    
    final messages = _chatHistory.getRecentMessages(days: 30);
    final grouped = _groupMessagesByDate(messages);
    
    setState(() {
      _allMessages = messages;
      _groupedMessages = grouped;
      _isLoading = false;
    });
  }

  Map<String, List<MessageModel>> _groupMessagesByDate(List<MessageModel> messages) {
    final grouped = <String, List<MessageModel>>{};
    
    for (final message in messages) {
      final dateKey = _getDateKey(message.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(message);
    }
    
    // Sort messages within each group (newest first)
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    
    return grouped;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (messageDate.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(date); // Monday, Tuesday, etc.
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2749),
        title: const Text(
          'Clear All History?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete all chat history. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear all sessions
      final sessions = _chatHistory.getAllSessions();
      for (final session in sessions) {
        await _chatHistory.deleteSession(session.id);
      }
      await _loadMessages();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat history cleared')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2749),
        elevation: 0,
        title: const Text(
          'Chat History',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (_allMessages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white70),
              onPressed: _clearAllHistory,
              tooltip: 'Clear all history',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A8E8)),
              ),
            )
          : _allMessages.isEmpty
              ? _buildEmptyState()
              : _buildHistoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No chat history yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with JARVIS',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final sortedKeys = _groupedMessages.keys.toList()
      ..sort((a, b) {
        // Sort by date (Today first, then Yesterday, etc.)
        final dateOrder = ['Today', 'Yesterday', 'Monday', 'Tuesday', 'Wednesday', 
                          'Thursday', 'Friday', 'Saturday', 'Sunday'];
        final indexA = dateOrder.indexOf(a);
        final indexB = dateOrder.indexOf(b);
        
        if (indexA != -1 && indexB != -1) {
          return indexA.compareTo(indexB);
        } else if (indexA != -1) {
          return -1;
        } else if (indexB != -1) {
          return 1;
        } else {
          // Parse dates for older entries
          try {
            final dateA = DateFormat('MMM d, yyyy').parse(a);
            final dateB = DateFormat('MMM d, yyyy').parse(b);
            return dateB.compareTo(dateA); // Newest first
          } catch (e) {
            return 0;
          }
        }
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final messages = _groupedMessages[dateKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                dateKey.toUpperCase(),
                style: TextStyle(
                  color: const Color(0xFF00A8E8).withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            // Messages for this date
            ...messages.map((message) => _buildMessageCard(message)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildMessageCard(MessageModel message) {
    final time = DateFormat('h:mm a').format(message.timestamp);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: message.isUser
            ? const Color(0xFF00A8E8).withOpacity(0.1)
            : const Color(0xFF1E2749),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: message.isUser
              ? const Color(0xFF00A8E8).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: message.isUser
                      ? const Color(0xFF00A8E8)
                      : const Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                message.isUser ? 'You' : 'JARVIS',
                style: TextStyle(
                  color: message.isUser
                      ? const Color(0xFF00A8E8)
                      : const Color(0xFFFF6B35),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
