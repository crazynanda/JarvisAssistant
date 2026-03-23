import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/jarvis_voice.dart';
import '../services/jarvis_api_service.dart';
import '../services/chat_history_service.dart';
import '../services/user_profile_service.dart';
import '../services/jarvis_listener.dart';
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

/// Themed home screen for J.A.R.V.I.S voice assistant
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
  final JarvisListener _wakeWordListener = JarvisListener();
  
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isListening = false;
  bool _wakeWordActive = false;
  bool _wakeWordEnabled = true;
  bool _microphonePermissionGranted = false;
  
  DateTime? _lastGreetingTime;
  Timer? _commandTimeoutTimer;
  static const Duration _commandTimeout = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    debugPrint('[J.A.R.V.I.S] Starting app initialization...');
    
    try {
      // Request microphone permission first
      _microphonePermissionGranted = await _requestMicrophonePermission();
      if (!_microphonePermissionGranted) {
        debugPrint('[J.A.R.V.I.S] Microphone permission denied');
        if (mounted) {
          _showError('Microphone permission required for voice features');
        }
        return;
      }
      
      await _loadSettings();
      debugPrint('[J.A.R.V.I.S] Settings loaded');
      
      await _loadChatHistory();
      debugPrint('[J.A.R.V.I.S] Chat history loaded');
      
      await _initializeVoiceService();
      debugPrint('[J.A.R.V.I.S] Voice service initialized');
      
      // Temporarily disable wake word to prevent crashes
      // await _initializeWakeWordListener();
      debugPrint('[J.A.R.V.I.S] Wake word listener DISABLED (temporarily)');
      
      await _speakWelcomeMessage();
      debugPrint('[J.A.R.V.I.S] App initialization complete');
    } catch (e) {
      debugPrint('[J.A.R.V.I.S] CRITICAL ERROR during initialization: $e');
      if (mounted) {
        _showError('App initialization failed. Please restart the app.');
      }
    }
  }
  
  Future<bool> _requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('[J.A.R.V.I.S] Permission request error: $e');
      return false;
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _wakeWordEnabled = prefs.getBool('wake_word_enabled') ?? true;
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
    final success = await _voiceService.initialize(skipPermissionCheck: true);
    debugPrint('[J.A.R.V.I.S] Voice service initialize result: $success');
    setState(() => _isInitialized = success);

    if (success) {
      debugPrint('[J.A.R.V.I.S] Setting up voice callbacks');
      
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
        
        // If voice service stops listening, restart wake word listener if enabled (disabled for now)
        // if (!_isListening && _wakeWordEnabled) {
        //   _restartWakeWordListener();
        // }
      };
    }
  }

  Future<void> _initializeWakeWordListener() async {
    debugPrint('[J.A.R.V.I.S] Wake word listener is DISABLED (temporarily)');
    // Temporarily disabled to prevent crashes
    // Will be re-enabled in Phase 2 with proper SpeechManager implementation
    return;
  }

  Future<void> _handleWakeWordDetected() async {
    debugPrint('[J.A.R.V.I.S] Wake word detected!');
    
    // Stop wake word listener to free up speech recognition
    await _wakeWordListener.stopListening();
    
    setState(() => _wakeWordActive = true);
    
    final now = DateTime.now();
    if (_lastGreetingTime == null || 
        now.difference(_lastGreetingTime!) > const Duration(seconds: 30)) {
      final greeting = _userProfile.getGreeting();
      _lastGreetingTime = now;
      await _voiceService.speak(greeting);
    }
    
    // Wait for greeting to finish
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Start voice service to listen for command
    if (_voiceService.isInitialized && !_voiceService.isListening) {
      await _voiceService.listen();
    }
  }

  void _restartWakeWordListener() {
    // Temporarily disabled to prevent crashes
    debugPrint('[J.A.R.V.I.S] Wake word restart disabled (temporarily)');
    return;
    
    // Original implementation (will be re-enabled in Phase 2):
    // if (!_wakeWordEnabled) return;
    // 
    // debugPrint('[J.A.R.V.I.S] Restarting wake word listener');
    // _wakeWordListener.startListening().then((_) {
    //   debugPrint('[J.A.R.V.I.S] Wake word listener restarted');
    // }).catchError((error) {
    //   debugPrint('[J.A.R.V.I.S] Failed to restart wake word listener: $error');
    // });
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

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _voiceService.stopListening();
    } else {
      await _voiceService.listen();
    }
  }

  void _addMessage(String text, {required bool isUser}) {
    setState(() {
      _messages.add(Message(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
    
    _chatHistory.saveMessage(text: text, isUser: isUser);
  }

  Future<void> _processUserMessage(String text) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    _commandTimeoutTimer?.cancel();
    _commandTimeoutTimer = Timer(_commandTimeout, () {
      if (_isProcessing) {
        setState(() => _isProcessing = false);
      }
    });
    
    try {
      _addMessage('Thinking...', isUser: false);
      
      final response = await _apiService.ask(text);
      
      _messages.removeLast();
      
      _addMessage(response, isUser: false);
      
      await _voiceService.speak(response);
      
    } catch (e) {
      _messages.removeLast();
      _addMessage('Sorry, I encountered an error. Please try again.', isUser: false);
      _showError('Error: $e');
    } finally {
      setState(() => _isProcessing = false);
      _userProfile.incrementConversations();
      
      // Restart wake word listener after processing command
      _restartWakeWordListener();
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    
    _textController.clear();
    _addMessage(text, isUser: true);
    await _processUserMessage(text);
  }
  
  Future<void> _startNewChat() async {
    setState(() {
      _messages.clear();
    });
    _chatHistory.clearCurrentSession();
    await _speakWelcomeMessage();
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

  @override
  void dispose() {
    _commandTimeoutTimer?.cancel();
    _textController.dispose();
    _voiceService.dispose();
    // _wakeWordListener.dispose(); // Temporarily disabled
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemedChatScreen(
      messages: _messages,
      isProcessing: _isProcessing,
      isListening: _isListening,
      textController: _textController,
      onSend: _sendMessage,
      onMicPressed: _toggleListening,
      onNewChat: _startNewChat,
      onSettings: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsScreen(
              wakeWordEnabled: _wakeWordEnabled,
              onWakeWordToggle: (value) {
                setState(() {
                  _wakeWordEnabled = value;
                });
              },
            ),
          ),
        );
      },
    );
  }
}