import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'elevenlabs_service.dart';

/// JarvisVoice - Voice recognition and text-to-speech service
/// Handles listening for voice commands and speaking responses
class JarvisVoice {
  // Speech to Text instance
  final SpeechToText _speech = SpeechToText();

  // Text to Speech instance (fallback)
  final FlutterTts _tts = FlutterTts();

  // ElevenLabs service (premium voice)
  final ElevenLabsService _elevenLabs = ElevenLabsService();

  // State management
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  // Silence detection
  Timer? _silenceTimer;
  String _lastRecognizedWords = '';

  // Callbacks
  Function(String)? onResult;
  Function(String)? onError;
  Function()? onListeningComplete;
  Function(bool)? onListeningStateChanged;

  // Configuration
  static const Duration _silenceTimeout = Duration(seconds: 5);
  static const String _defaultLocale = 'en_US';

  /// Initialize the voice service
  /// Returns true if initialization is successful
  Future<bool> initialize() async {
    try {
      // Request microphone permission
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        _handleError('Microphone permission denied');
        return false;
      }

      // Initialize Speech to Text
      final speechAvailable = await _speech.initialize(
        onError: (error) =>
            _handleError('Speech recognition error: ${error.errorMsg}'),
        onStatus: (status) => _handleStatusChange(status),
      );

      if (!speechAvailable) {
        _handleError('Speech recognition not available on this device');
        return false;
      }

      // Initialize Text to Speech (fallback)
      await _configureTts();

      // Initialize ElevenLabs
      await _elevenLabs.initialize();

      _isInitialized = true;
      if (kDebugMode) {
        print('JarvisVoice initialized successfully');
      }
      return true;
    } catch (e) {
      _handleError('Initialization error: $e');
      return false;
    }
  }

  /// Configure Text-to-Speech settings
  Future<void> _configureTts() async {
    try {
      await _tts.setLanguage(_defaultLocale);
      await _tts.setSpeechRate(0.5); // Slightly slower for clarity
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true); // Wait for speech to finish

      // Set completion handler
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        if (kDebugMode) {
          print('TTS completed');
        }
      });

      // Set error handler
      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        _handleError('TTS error: $msg');
      });
    } catch (e) {
      _handleError('TTS configuration error: $e');
    }
  }

  /// Start listening for voice input
  /// Returns the recognized text when listening completes
  Future<String> listen() async {
    if (!_isInitialized) {
      _handleError('JarvisVoice not initialized. Call initialize() first.');
      return '';
    }

    if (_isListening) {
      _handleError('Already listening');
      return '';
    }

    if (_isSpeaking) {
      // Stop speaking before listening
      await stopSpeaking();
    }

    try {
      _lastRecognizedWords = '';
      _isListening = true;
      onListeningStateChanged?.call(true);

      // Start listening
      await _speech.listen(
        onResult: (result) => _handleSpeechResult(result),
        listenFor: const Duration(seconds: 30), // Maximum listen duration
        pauseFor: const Duration(seconds: 5), // Pause detection
        localeId: _defaultLocale,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
      );

      // Start silence timer
      _resetSilenceTimer();

      if (kDebugMode) {
        print('Started listening...');
      }

      return _lastRecognizedWords;
    } catch (e) {
      _isListening = false;
      onListeningStateChanged?.call(false);
      _handleError('Listen error: $e');
      return '';
    }
  }

  /// Handle speech recognition results
  void _handleSpeechResult(SpeechRecognitionResult result) {
    final recognizedWords = result.recognizedWords;

    if (recognizedWords.isNotEmpty) {
      _lastRecognizedWords = recognizedWords;

      // Reset silence timer on new words
      _resetSilenceTimer();

      // If result is final, stop listening
      if (result.finalResult) {
        _stopListening();
      }

      if (kDebugMode) {
        print('Recognized: $recognizedWords (final: ${result.finalResult})');
      }
    }
  }

  /// Reset the silence detection timer
  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(_silenceTimeout, () {
      if (_isListening) {
        if (kDebugMode) {
          print('Silence detected - auto-stopping');
        }
        _stopListening();
      }
    });
  }

  /// Stop listening
  Future<void> _stopListening() async {
    if (!_isListening) return;

    try {
      _silenceTimer?.cancel();
      await _speech.stop();
      _isListening = false;
      onListeningStateChanged?.call(false);

      // Notify with result
      if (_lastRecognizedWords.isNotEmpty) {
        onResult?.call(_lastRecognizedWords);
      }

      onListeningComplete?.call();

      if (kDebugMode) {
        print('Stopped listening. Final result: $_lastRecognizedWords');
      }
    } catch (e) {
      _handleError('Stop listening error: $e');
    }
  }

  /// Manually stop listening (public method)
  Future<void> stopListening() async {
    await _stopListening();
  }

  /// Speak the given text using text-to-speech
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      _handleError('JarvisVoice not initialized. Call initialize() first.');
      return;
    }

    if (text.isEmpty) {
      _handleError('Cannot speak empty text');
      return;
    }

    try {
      // Stop any ongoing speech
      if (_isSpeaking) {
        await _tts.stop();
      }

      // Stop listening if active
      if (_isListening) {
        await stopListening();
      }

      _isSpeaking = true;

      if (kDebugMode) {
        print('Speaking: $text');
      }

      // Try ElevenLabs first if enabled
      if (_elevenLabs.isEnabled) {
        try {
          await _elevenLabs.speak(text);
          _isSpeaking = false;
          return;
        } catch (e) {
          if (kDebugMode) {
            print('ElevenLabs failed, falling back to TTS: $e');
          }
          // Fall through to flutter_tts
        }
      }

      // Use flutter_tts as fallback
      await _tts.speak(text);
    } catch (e) {
      _isSpeaking = false;
      _handleError('Speak error: $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _tts.stop();
      _isSpeaking = false;
    }
  }

  /// Handle status changes from speech recognition
  void _handleStatusChange(String status) {
    if (kDebugMode) {
      print('Speech status: $status');
    }

    if (status == 'done' || status == 'notListening') {
      if (_isListening) {
        _stopListening();
      }
    }
  }

  /// Handle errors
  void _handleError(String error) {
    if (kDebugMode) {
      print('JarvisVoice Error: $error');
    }
    onError?.call(error);
  }

  /// Restart the voice service
  /// Useful for recovering from errors
  Future<bool> restart() async {
    try {
      if (kDebugMode) {
        print('Restarting JarvisVoice...');
      }

      // Stop any ongoing operations
      await stopListening();
      await stopSpeaking();

      // Cancel timers
      _silenceTimer?.cancel();

      // Reset state
      _isListening = false;
      _isSpeaking = false;
      _lastRecognizedWords = '';

      // Reinitialize
      _isInitialized = false;
      return await initialize();
    } catch (e) {
      _handleError('Restart error: $e');
      return false;
    }
  }

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Get ElevenLabs service for configuration
  ElevenLabsService get elevenLabs => _elevenLabs;

  /// Get available locales for speech recognition
  Future<List<String>> getAvailableLocales() async {
    if (!_isInitialized) return [];

    try {
      final locales = await _speech.locales();
      return locales.map((locale) => locale.localeId).toList();
    } catch (e) {
      _handleError('Get locales error: $e');
      return [];
    }
  }

  /// Dispose resources
  void dispose() {
    _silenceTimer?.cancel();
    _speech.stop();
    _tts.stop();
    _isListening = false;
    _isSpeaking = false;
    _isInitialized = false;

    if (kDebugMode) {
      print('JarvisVoice disposed');
    }
  }
}
