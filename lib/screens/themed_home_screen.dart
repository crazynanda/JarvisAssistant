import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/jarvis_voice.dart';
import '../services/jarvis_listener.dart';
import '../services/jarvis_api_service.dart';
import 'settings_screen.dart';
import 'themes/themed_chat_screen.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// Themed home screen that uses ThemedChatScreen for unique theme UIs
class ThemedHomeScreen extends StatefulWidget {
  const ThemedHomeScreen({super.key});

  @override
  State<ThemedHomeScreen> createState() => _ThemedHomeScreenState();
}

class _ThemedHomeScreenState extends State<ThemedHomeScreen> {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final JarvisVoice _voiceService = JarvisVoice();
  final JarvisListener _wakeWordListener = JarvisListener();
  final JarvisApiService _apiService = JarvisApiService();
  bool _isListening = false;
  bool _isInitialized = false;
  bool _wakeWordDetected = false;
  bool _wakeWordEnabled = true;
  bool _isProcessing = false;

  // Greeting state
  DateTime? _lastGreetingTime;
  final List<String> _greetings = [
    "Online and listening, sir.",
    "At your service.",
  ];

  @override
  void initState() {
    super.initState();

    // Delay initialization to prevent blocking main thread
    Future.delayed(Duration.zero, () {
      _loadSettings();
      _initializeVoiceService();
    });
  }

  Future<void> _loadSettings() async {
    final enabled = await SettingsManager.getWakeWordEnabled();
    setState(() {
      _wakeWordEnabled = enabled;
    });

    if (_wakeWordEnabled) {
      _initializeWakeWordListener();
    }
  }

  Future<void> _toggleWakeWord(bool enabled) async {
    setState(() {
      _wakeWordEnabled = enabled;
    });

    await SettingsManager.setWakeWordEnabled(enabled);

    if (enabled) {
      await _initializeWakeWordListener();
    } else {
      await _wakeWordListener.stopListening();
    }
  }

  Future<void> _initializeVoiceService() async {
    final success = await _voiceService.initialize();

    setState(() {
      _isInitialized = success;
    });

    if (success) {
      // Set up callbacks
      _voiceService.onResult = (text) {
        if (text.isNotEmpty) {
          _addMessage(text, isUser: true);
          _processUserMessage(text);
        }
      };

      _voiceService.onError = (error) {
        _showError(error);
      };

      _voiceService.onListeningStateChanged = (isListening) {
        setState(() {
          _isListening = isListening;
        });
      };

      // Add welcome message and speak it
      const welcomeMsg =
          'Hello! I am Jarvis, your personal assistant. How may I help you today?';
      _addMessage(welcomeMsg, isUser: false);
      await _voiceService.speak(welcomeMsg);
    } else {
      _showError(
          'Failed to initialize voice service. Please check permissions.');
    }
  }

  Future<void> _initializeWakeWordListener() async {
    final success = await _wakeWordListener.initialize();

    if (success) {
      // Set up wake word callbacks
      _wakeWordListener.onWakeWordDetected = _handleWakeWordDetected;

      _wakeWordListener.onError = (error) {
        if (mounted) {
          _showError('Wake word: $error');
        }
      };

      _wakeWordListener.onReturnToIdle = () {
        if (mounted) {
          setState(() {
            _wakeWordDetected = false;
          });
        }
      };

      // Start listening for wake word in background
      await _wakeWordListener.startListening();

      if (kDebugMode) {
        print('Wake word detection started - say "JARVIS" to activate');
      }
    } else {
      // Silently fail - wake word is optional, app works fine without it
      if (kDebugMode) {
        print('Wake word detection not available - continuing without it');
      }
    }
  }

  Future<void> _handleWakeWordDetected() async {
    if (mounted) {
      setState(() {
        _wakeWordDetected = true;
      });

      // Wait for activation sound to play (handled in JarvisListener)
      await Future.delayed(const Duration(milliseconds: 500));

      // Play greeting if enough time has passed (30s window)
      final now = DateTime.now();
      if (_lastGreetingTime == null ||
          now.difference(_lastGreetingTime!) > const Duration(seconds: 30)) {
        // Pick random greeting
        final greeting = (_greetings..shuffle()).first;

        // Update last greeting time
        _lastGreetingTime = now;

        // Speak greeting and wait for it to finish
        if (_voiceService.isInitialized) {
          await _voiceService.speak(greeting);
        }
      }

      // Start voice recognition
      if (_voiceService.isInitialized && !_voiceService.isListening) {
        await _voiceService.listen();
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _voiceService.dispose();
    _wakeWordListener.dispose();
    super.dispose();
  }

  void _addMessage(String text, {required bool isUser}) {
    setState(() {
      _messages.add(Message(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _toggleListening() async {
    if (!_isInitialized) {
      _showError('Voice service not initialized');
      return;
    }

    if (_isListening) {
      // Stop listening
      await _voiceService.stopListening();
    } else {
      // Start listening
      await _voiceService.listen();
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Clear the text field
    _textController.clear();

    // Add user message
    _addMessage(text, isUser: true);

    // Process the message (same as voice)
    await _processUserMessage(text);
  }

  Future<void> _processUserMessage(String userMessage) async {
    // Reset idle timer on wake word listener
    _wakeWordListener.resetIdleTimer();

    // Set processing state
    setState(() {
      _isProcessing = true;
    });

    try {
      // Call backend API
      final response = await _apiService.ask(userMessage);

      _addMessage(response, isUser: false);
      await _voiceService.speak(response);
    } catch (e) {
      _showError('Error: $e');
      _addMessage("I'm having trouble connecting to my servers, sir.",
          isUser: false);
    } finally {
      // Clear processing state
      setState(() {
        _isProcessing = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return ThemedChatScreen(
      messages: _messages,
      isProcessing: _isProcessing,
      isListening: _isListening || _wakeWordDetected,
      textController: _textController,
      onSend: _sendMessage,
      onMicPressed: _toggleListening,
      onNewChat: () {
        setState(() {
          _messages.clear();
        });
      },
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
