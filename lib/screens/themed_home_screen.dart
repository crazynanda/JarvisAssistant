import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/jarvis_voice.dart';
import '../services/jarvis_api_service.dart';
import '../services/chat_history_service.dart';
import '../services/user_profile_service.dart';
import '../services/unified_wake_word_service.dart';
import '../models/message_model.dart';
import '../widgets/quick_action_chips.dart';
import 'settings_screen.dart';
import 'themes/themed_chat_screen.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? quickActions;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.quickActions,
  });
}

/// Themed home screen with Alexa-style wake word detection
class ThemedHomeScreen extends StatefulWidget {
  const ThemedHomeScreen({super.key});

  @override
  State<ThemedHomeScreen> createState() => _ThemedHomeScreenState();
}

class _ThemedHomeScreenState extends State<ThemedHomeScreen> {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final JarvisVoice _voiceService = JarvisVoice();
  final JarvisApiService _apiService = JarvisApiService();
  final ChatHistoryService _chatHistory = ChatHistoryService();
  final UserProfileService _userProfile = UserProfileService();
  final UnifiedWakeWordService _wakeWordService = UnifiedWakeWordService();
  
  // State management
  bool _isListening = false;
  bool _isInitialized = false;
  bool _wakeWordDetected = false;
  bool _wakeWordEnabled = true;
  bool _isProcessing = false;
  bool _isPushToTalkActive = false;
  
  // Timing
  DateTime? _lastGreetingTime;
  Timer? _commandTimeoutTimer;
  static const Duration _commandTimeout = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    
    // Delay initialization
    Future.delayed(Duration.zero, () {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    debugPrint('[J.A.R.V.I.S] Starting app initialization...');
    
    await _loadSettings();
    debugPrint('[J.A.R.V.I.S] Settings loaded: wakeWordEnabled=$_wakeWordEnabled');
    
    await _loadChatHistory();
    debugPrint('[J.A.R.V.I.S] Chat history loaded');
    
    await _initializeVoiceService();
    debugPrint('[J.A.R.V.I.S] Voice service initialized');
    
    await _initializeWakeWordService();
    debugPrint('[J.A.R.V.I.S] Wake word service initialized');
  }

  Future<void> _loadSettings() async {
    final enabled = await SettingsManager.getWakeWordEnabled();
    setState(() {
      _wakeWordEnabled = enabled;
    });
  }

  Future<void> _loadChatHistory() async {
    try {
      final savedMessages = _chatHistory.getCurrentSessionMessages();
      if (savedMessages.isNotEmpty) {
        setState(() {
          _messages.addAll(savedMessages.map((msg) => Message(
            text: msg.text,
            isUser: msg.isUser,
            timestamp: msg.timestamp,
          )));
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error loading chat history: $e');
    }
  }

  Future<void> _initializeVoiceService() async {
    debugPrint('[J.A.R.V.I.S] Initializing voice service...');
    final success = await _voiceService.initialize();
    debugPrint('[J.A.R.V.I.S] Voice service initialize result: $success');
    setState(() => _isInitialized = success);

    if (success) {
      debugPrint('[J.A.R.V.I.S] Sharing SpeechToText instance with wake word service');
      // CRITICAL: Share SpeechToText instance with wake word service
      // This prevents conflicts - Android only supports ONE speech recognition session
      UnifiedWakeWordService.setSharedSpeechInstance(_voiceService.speechInstance);

      // Set up voice callbacks
      _voiceService.onResult = (text) {
        if (text.isNotEmpty) {
          _addMessage(text, isUser: true);
          _processUserMessage(text);
        }
      };

      _voiceService.onError = (error) => _showError(error);
      
      _voiceService.onListeningStateChanged = (isListening) {
        debugPrint('[J.A.R.V.I.S] Voice listening state: $isListening');
        setState(() => _isListening = isListening);
        
        // Coordinate with wake word service
        if (isListening) {
          _wakeWordService.pause();
        } else {
          _wakeWordService.resume();
        }
      };

      // Welcome message
      _speakWelcomeMessage();
    }
  }

  Future<void> _initializeWakeWordService() async {
    debugPrint('[J.A.R.V.I.S] Initializing wake word service... preferredGreeting: ${_userProfile.preferredGreeting}');
    
    // Initialize with user's preferred greeting
    final success = await _wakeWordService.initialize(
      preferredGreeting: _userProfile.preferredGreeting,
    );
    
    debugPrint('[J.A.R.V.I.S] Wake word service initialize result: $success');

    if (success) {
      debugPrint('[J.A.R.V.I.S] Setting up wake word callbacks');
      // Set up wake word callback
      _wakeWordService.onWakeWordDetected = _handleWakeWordDetected;
      _wakeWordService.onError = (error) => _showError('Wake word: $error');
      
      // Auto-start if enabled
      if (_wakeWordEnabled) {
        debugPrint('[J.A.R.V.I.S] Starting wake word detection (enabled)');
        await _wakeWordService.start();
      } else {
        debugPrint('[J.A.R.V.I.S] Wake word detection NOT started (disabled in settings)');
      }

      // Check if launched by wake word
      final wasLaunched = await _wakeWordService.wasLaunchedByWakeWord();
      if (wasLaunched) {
        debugPrint('[J.A.R.V.I.S] App was launched by wake word');
        _handleWakeWordDetected();
      }
    } else {
      debugPrint('[J.A.R.V.I.S] WAKE WORD SERVICE FAILED TO INITIALIZE!');
    }
  }

  Future<void> _speakWelcomeMessage() async {
    String welcomeMsg;
    if (_messages.isEmpty) {
      welcomeMsg = _userProfile.isFirstTimeUser
          ? 'Hello! I am JARVIS, your personal assistant. How may I help you today?'
          : _userProfile.getGreeting();
    } else {
      welcomeMsg = _userProfile.getWelcomeBackMessage();
    }
    
    await _voiceService.speak(welcomeMsg);
    _userProfile.updateLastActive();
  }

  /// Alexa-style wake word response
  Future<void> _handleWakeWordDetected() async {
    final stopwatch = Stopwatch()..start();
    
    if (kDebugMode) {
      print('🎯 Wake word detected! Stopping all audio...');
    }

    // 1. STOP ALL AUDIO IMMEDIATELY (0ms)
    await _voiceService.stopSpeaking();
    await _voiceService.stopListening();
    
    // 2. Pause wake word detection while listening for command
    _wakeWordService.pause();
    
    // 3. Reset state
    _commandTimeoutTimer?.cancel();
    setState(() {
      _wakeWordDetected = true;
      _isProcessing = false;
    });

    // 4. Play greeting "Yes sir" (50-100ms)
    final greeting = "Yes ${_userProfile.preferredGreeting}";
    await _voiceService.speak(greeting);

    // 5. Start listening for command (100ms)
    if (_voiceService.isInitialized) {
      await _voiceService.listen();
      
      // Start 5-second timeout
      _startCommandTimeout();
    }

    final elapsed = stopwatch.elapsedMilliseconds;
    if (kDebugMode) {
      print('✅ Wake word response time: ${elapsed}ms');
    }
  }

  void _startCommandTimeout() {
    _commandTimeoutTimer?.cancel();
    _commandTimeoutTimer = Timer(_commandTimeout, () {
      if (mounted && _voiceService.isListening) {
        _voiceService.stopListening();
        setState(() => _wakeWordDetected = false);
        _wakeWordService.resume();
        if (kDebugMode) print('⏱️ Command timeout - returning to idle');
      }
    });
  }

  void _addMessage(String text, {required bool isUser, bool saveToHistory = true, List<String>? quickActions}) {
    final actions = !isUser && quickActions == null
        ? QuickActionGenerator.generateActions(text)
        : quickActions;

    setState(() {
      _messages.add(Message(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
        quickActions: actions,
      ));
    });

    if (saveToHistory) {
      _chatHistory.saveMessage(text: text, isUser: isUser, quickActions: actions);
    }
  }

  Future<void> _processUserMessage(String userMessage) async {
    _commandTimeoutTimer?.cancel();
    
    setState(() => _isProcessing = true);

    try {
      final response = await _apiService.ask(userMessage);
      _addMessage(response, isUser: false);
      await _voiceService.speak(response);
      await _userProfile.incrementConversations();
    } catch (e) {
      _showError('Error: $e');
      _addMessage("I'm having trouble connecting to my servers, ${_userProfile.preferredGreeting}.", isUser: false);
    } finally {
      setState(() {
        _isProcessing = false;
        _wakeWordDetected = false;
      });
      
      // Resume wake word detection after command is processed
      _wakeWordService.resume();
    }
  }

  /// Push-to-talk: Long press handlers
  void _onPushToTalkStart() {
    setState(() => _isPushToTalkActive = true);
    // Stop wake word first to avoid conflict
    _wakeWordService.pause();
    _voiceService.listen();
    if (kDebugMode) print('👆 Push-to-talk START');
  }

  void _onPushToTalkEnd() {
    setState(() => _isPushToTalkActive = false);
    _voiceService.stopListening();
    // Resume wake word after command listening ends
    _wakeWordService.resume();
    if (kDebugMode) print('👆 Push-to-talk END');
  }

  Future<void> _toggleListening() async {
    if (!_isInitialized) {
      _showError('Voice service not initialized');
      return;
    }

    if (_isListening) {
      await _voiceService.stopListening();
      _wakeWordService.resume();
    } else {
      // Stop wake word first
      _wakeWordService.pause();
      await _voiceService.listen();
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    _addMessage(text, isUser: true);
    await _processUserMessage(text);
  }

  Future<void> _toggleWakeWord(bool enabled) async {
    setState(() => _wakeWordEnabled = enabled);
    await SettingsManager.setWakeWordEnabled(enabled);

    if (enabled) {
      await _wakeWordService.start();
    } else {
      await _wakeWordService.stop();
    }
  }

  void _showError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _startNewChat() async {
    await _chatHistory.startNewSession();
    setState(() => _messages.clear());
    
    final welcomeMsg = 'New session started. How can I help you?';
    _addMessage(welcomeMsg, isUser: false);
    await _voiceService.speak(welcomeMsg);
  }

  @override
  void dispose() {
    _commandTimeoutTimer?.cancel();
    _textController.dispose();
    _voiceService.dispose();
    _wakeWordService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemedChatScreen(
      messages: _messages,
      isProcessing: _isProcessing,
      isListening: _isListening || _wakeWordDetected || _isPushToTalkActive,
      textController: _textController,
      onSend: _sendMessage,
      onMicPressed: _toggleListening,
      onMicLongPressStart: _onPushToTalkStart,
      onMicLongPressEnd: _onPushToTalkEnd,
      onNewChat: _startNewChat,
      onSettings: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsScreen(
              wakeWordEnabled: _wakeWordEnabled,
              onWakeWordToggle: _toggleWakeWord,
            ),
          ),
        );
      },
    );
  }
}
