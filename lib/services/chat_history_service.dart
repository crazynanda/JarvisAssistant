import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';

/// Service for managing chat history with Hive
class ChatHistoryService {
  static final ChatHistoryService _instance = ChatHistoryService._internal();
  factory ChatHistoryService() => _instance;
  ChatHistoryService._internal();

  static const String _messagesBoxName = 'messages';
  static const String _sessionsBoxName = 'sessions';
  static const String _currentSessionKey = 'current_session_id';
  
  Box<MessageModel>? _messagesBox;
  Box<ChatSession>? _sessionsBox;
  final _uuid = const Uuid();
  String? _currentSessionId;

  /// Initialize Hive boxes
  Future<void> initialize() async {
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MessageModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ChatSessionAdapter());
    }
    
    _messagesBox = await Hive.openBox<MessageModel>(_messagesBoxName);
    _sessionsBox = await Hive.openBox<ChatSession>(_sessionsBoxName);
    
    // Get or create current session
    await _initializeCurrentSession();
  }

  /// Initialize or retrieve current session
  Future<void> _initializeCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    _currentSessionId = prefs.getString(_currentSessionKey);
    
    if (_currentSessionId == null || _sessionsBox?.get(_currentSessionId) == null) {
      await startNewSession();
    }
  }

  /// Start a new chat session
  Future<String> startNewSession({String? title}) async {
    final sessionId = _uuid.v4();
    final session = ChatSession(
      id: sessionId,
      title: title ?? 'Chat ${_sessionsBox?.length ?? 1}',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );
    
    await _sessionsBox?.put(sessionId, session);
    
    // Save current session ID using SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentSessionKey, sessionId);
    _currentSessionId = sessionId;
    
    return sessionId;
  }

  /// Save a message to current session
  Future<void> saveMessage({
    required String text,
    required bool isUser,
    List<String>? quickActions,
    bool hasAttachment = false,
    String? attachmentType,
  }) async {
    if (_currentSessionId == null) {
      await _initializeCurrentSession();
    }

    final message = MessageModel(
      id: _uuid.v4(),
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
      sessionId: _currentSessionId,
      quickActions: quickActions,
      hasAttachment: hasAttachment,
      attachmentType: attachmentType,
    );

    await _messagesBox?.add(message);
    
    // Update session last modified
    final session = _sessionsBox?.get(_currentSessionId);
    if (session != null) {
      final updatedSession = ChatSession(
        id: session.id,
        title: session.title,
        createdAt: session.createdAt,
        lastModified: DateTime.now(),
        messageCount: (session.messageCount) + 1,
        summary: session.summary,
      );
      await _sessionsBox?.put(session.id, updatedSession);
    }
  }

  /// Get messages for current session
  List<MessageModel> getCurrentSessionMessages() {
    if (_currentSessionId == null) return [];
    
    return _messagesBox?.values
        .where((msg) => msg.sessionId == _currentSessionId)
        .toList() ?? [];
  }

  /// Get messages from last N days
  List<MessageModel> getRecentMessages({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    
    return _messagesBox?.values
        .where((msg) => msg.timestamp.isAfter(cutoff))
        .toList() ?? [];
  }

  /// Get messages grouped by date
  Map<String, List<MessageModel>> getMessagesGroupedByDate() {
    final messages = getCurrentSessionMessages();
    final grouped = <String, List<MessageModel>>{};
    
    for (final message in messages) {
      final key = _getDateKey(message.timestamp);
      grouped.putIfAbsent(key, () => []).add(message);
    }
    
    return grouped;
  }

  /// Get date key for grouping (Today, Yesterday, or date)
  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Get all sessions
  List<ChatSession> getAllSessions() {
    return _sessionsBox?.values.toList() ?? [];
  }

  /// Get messages for a specific session
  List<MessageModel> getSessionMessages(String sessionId) {
    return _messagesBox?.values
        .where((msg) => msg.sessionId == sessionId)
        .toList() ?? [];
  }

  /// Switch to a different session
  Future<void> switchSession(String sessionId) async {
    if (_sessionsBox?.containsKey(sessionId) == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentSessionKey, sessionId);
      _currentSessionId = sessionId;
    }
  }

  /// Delete a session and its messages
  Future<void> deleteSession(String sessionId) async {
    // Delete all messages for this session
    final messagesToDelete = _messagesBox?.values
        .where((msg) => msg.sessionId == sessionId)
        .toList();
    
    for (final message in messagesToDelete ?? []) {
      await message.delete();
    }
    
    // Delete the session
    await _sessionsBox?.delete(sessionId);
    
    // If current session was deleted, start new one
    if (_currentSessionId == sessionId) {
      await startNewSession();
    }
  }

  /// Clear current session messages
  Future<void> clearCurrentSession() async {
    if (_currentSessionId == null) return;
    
    final messagesToDelete = _messagesBox?.values
        .where((msg) => msg.sessionId == _currentSessionId)
        .toList();
    
    for (final message in messagesToDelete ?? []) {
      await message.delete();
    }
  }

  /// Search messages
  List<MessageModel> searchMessages(String query) {
    final lowerQuery = query.toLowerCase();
    return _messagesBox?.values
        .where((msg) => msg.text.toLowerCase().contains(lowerQuery))
        .toList() ?? [];
  }

  /// Get current session ID
  String? get currentSessionId => _currentSessionId;

  /// Get current session info
  ChatSession? get currentSession {
    if (_currentSessionId == null) return null;
    return _sessionsBox?.get(_currentSessionId);
  }

  /// Get message count for current session
  int get currentSessionMessageCount {
    return getCurrentSessionMessages().length;
  }

  /// Get total message count across all sessions
  int get totalMessageCount {
    return _messagesBox?.length ?? 0;
  }

  /// Close boxes
  Future<void> dispose() async {
    await _messagesBox?.close();
    await _sessionsBox?.close();
  }
}
