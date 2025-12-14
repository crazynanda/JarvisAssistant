import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'services/jarvis_voice.dart';
import 'services/jarvis_listener.dart';
import 'services/file_upload_service.dart';
import 'services/jarvis_api_service.dart';
import 'services/wake_word_manager.dart';
import 'screens/settings_screen.dart';
import 'screens/themed_home_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'widgets/jarvis_orb.dart';
import 'widgets/typing_indicator.dart';
import 'themes/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize wake word manager
  await WakeWordManager.instance.initialize();

  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: const JarvisAssistantApp(),
    ),
  );
}

class JarvisAssistantApp extends StatelessWidget {
  const JarvisAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.theme;

        return MaterialApp(
          title: 'J.A.R.V.I.S',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.primaryColor,
              brightness: Brightness.dark,
              primary: theme.primaryColor,
              secondary: theme.accentColor,
              surface: theme.surfaceColor,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: theme.backgroundColor,
            fontFamily: theme.fontFamily,
          ),
          home: const ThemedHomeScreen(),
        );
      },
    );
  }
}

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

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  final JarvisVoice _voiceService = JarvisVoice();
  final JarvisListener _wakeWordListener = JarvisListener();
  final FileUploadService _fileUploadService = FileUploadService();
  final JarvisApiService _apiService = JarvisApiService();
  bool _isListening = false;
  bool _isInitialized = false;
  bool _wakeWordDetected = false;
  bool _wakeWordEnabled = true;
  bool _isProcessing = false;
  bool _hasText = false;

  // Greeting state
  DateTime? _lastGreetingTime;
  final List<String> _greetings = [
    "Online and listening, sir.",
    "At your service.",
  ];

  @override
  void initState() {
    super.initState();

    // Listen for text changes
    _textController.addListener(() {
      setState(() {
        _hasText = _textController.text.trim().isNotEmpty;
      });
    });

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

      // Animate mic glow (handled by state change)
      // _glowController was removed to prevent ANR

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
    _scrollController.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
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

    // Scroll to bottom after adding message
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Clear the text field
    _textController.clear();

    // Unfocus keyboard
    _textFocusNode.unfocus();

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

  Future<void> _handleFileUpload() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      final result = await _fileUploadService.pickAndAnalyzeFile();

      if (result != null && result['success'] == true) {
        // Add user message showing file was uploaded
        _addMessage(
          'Uploaded ${result['filename']}',
          isUser: true,
        );

        // Add assistant message with summary
        _addMessage(
          result['summary'],
          isUser: false,
        );

        // Speak the summary
        await _voiceService.speak(result['summary']);
      }
    } catch (e) {
      _showError('Error analyzing file: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleImageUpload() async {
    // Show dialog to choose camera or gallery
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2749),
        title: const Text(
          'Select Image Source',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF00A8E8)),
              title: const Text(
                'Camera',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Color(0xFF00A8E8)),
              title: const Text(
                'Gallery',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      final result =
          await _fileUploadService.pickAndAnalyzeImage(source: source);

      if (result != null && result['success'] == true) {
        // Add user message showing image was uploaded
        _addMessage(
          'Uploaded image: ${result['filename']}',
          isUser: true,
        );

        // Add assistant message with summary
        _addMessage(
          result['summary'],
          isUser: false,
        );

        // Speak the summary
        await _voiceService.speak(result['summary']);
      }
    } catch (e) {
      _showError('Error analyzing image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2749),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00A8E8).withValues(alpha: 0.8),
                    const Color(0xFF00A8E8).withValues(alpha: 0.2),
                  ],
                ),
              ),
              child: const Icon(
                Icons.circle,
                size: 12,
                color: Color(0xFF00A8E8),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'J.A.R.V.I.S.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Color(0xFF00A8E8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () async {
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
          ),
        ],
      ),
      body: Stack(
        children: [
          // Futuristic Background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Color(0xFF1E2749),
                  Color(0xFF0A0E27),
                ],
              ),
            ),
          ),

          // Jarvis Orb (Centered)
          Center(
            child: JarvisOrb(
              isProcessing: _isProcessing,
              isListening: _isListening || _wakeWordDetected,
              size: 250,
            ),
          ),

          // Chat messages
          Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? const SizedBox() // Empty state handled by Orb
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 100, // Space for input bar
                        ),
                        itemCount: _messages.length + (_isProcessing ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return const TypingIndicator();
                          }
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
              ),
            ],
          ),

          // Bottom input bar with text field and buttons
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2749),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFF00A8E8).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  // File upload button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isProcessing
                            ? null
                            : () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: const Color(0xFF1E2749),
                                  builder: (context) => Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: const Icon(
                                              Icons.insert_drive_file,
                                              color: Color(0xFF00A8E8)),
                                          title: const Text('Upload PDF',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _handleFileUpload();
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.image,
                                              color: Color(0xFF00A8E8)),
                                          title: const Text('Upload Image',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _handleImageUpload();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                        customBorder: const CircleBorder(),
                        child: const Icon(
                          Icons.attach_file,
                          color: Color(0xFF00A8E8),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Text input field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _textFocusNode,
                      enabled: !_isProcessing,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onSubmitted: (_) => _sendTextMessage(),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send button (always visible, enabled when typing)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _hasText
                            ? [const Color(0xFF00A8E8), const Color(0xFF0077B6)]
                            : [
                                const Color(0xFF2A3254),
                                const Color(0xFF1E2749)
                              ],
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: (_isProcessing || !_hasText)
                            ? null
                            : _sendTextMessage,
                        customBorder: const CircleBorder(),
                        child: Icon(
                          Icons.send,
                          color: _hasText ? Colors.white : Colors.white38,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Mic button (always visible, shows wake word state)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isListening
                            ? [const Color(0xFFFFA500), const Color(0xFFFF8C00)]
                            : _wakeWordDetected
                                ? [
                                    const Color(0xFF00FF88),
                                    const Color(0xFF00CC66)
                                  ]
                                : [
                                    const Color(0xFF00A8E8),
                                    const Color(0xFF0077B6)
                                  ],
                      ),
                      boxShadow: (_isListening || _wakeWordDetected)
                          ? [
                              BoxShadow(
                                color: (_isListening
                                        ? const Color(0xFFFFA500)
                                        : const Color(0xFF00FF88))
                                    .withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _toggleListening,
                        customBorder: const CircleBorder(),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
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
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            // Assistant avatar
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00A8E8).withValues(alpha: 0.6),
                    const Color(0xFF00A8E8).withValues(alpha: 0.2),
                  ],
                ),
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 18,
                color: Color(0xFF00A8E8),
              ),
            ),
          ],

          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF00A8E8),
                          Color(0xFF0077B6),
                        ],
                      )
                    : const LinearGradient(
                        colors: [
                          Color(0xFF1E2749),
                          Color(0xFF2A3254),
                        ],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: message.isUser
                        ? const Color(0xFF00A8E8).withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  color: message.isUser
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.9),
                  height: 1.4,
                ),
              ),
            ),
          ),

          if (message.isUser) ...[
            // User avatar
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF00A8E8),
                    Color(0xFF0077B6),
                  ],
                ),
              ),
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
