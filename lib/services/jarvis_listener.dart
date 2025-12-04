import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';

/// JarvisListener - Background wake word detection service
/// Continuously listens for the wake word "JARVIS" at low power
class JarvisListener {
  // Speech to Text instance for wake word detection
  final SpeechToText _speech = SpeechToText();

  // Audio player for activation sound
  final AudioPlayer _audioPlayer = AudioPlayer();

  // State management
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isActive = false; // True when wake word detected and processing command

  // Wake word configuration
  static const String _wakeWord = 'jarvis';
  static const List<String> _wakeWordVariants = [
    'jarvis',
    'jarvis',
    'jar vis',
    'jarvice',
    'jarves',
  ];

  // Timers
  Timer? _restartTimer;
  Timer? _idleTimer;

  // Callbacks
  Function()? onWakeWordDetected;
  Function(String)? onError;
  Function(bool)? onListeningStateChanged;
  Function()? onReturnToIdle;

  // Configuration
  static const Duration _idleTimeout = Duration(seconds: 5);
  static const Duration _restartDelay = Duration(seconds: 2);
  static const String _activationSoundPath = 'sounds/activation.mp3';

  /// Initialize the wake word listener
  Future<bool> initialize() async {
    try {
      // Request microphone permission
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        _handleError('Microphone permission denied for wake word detection');
        return false;
      }

      // Initialize Speech to Text
      final speechAvailable = await _speech.initialize(
        onError: (error) => _handleSpeechError(error.errorMsg),
        onStatus: (status) => _handleStatusChange(status),
      );

      if (!speechAvailable) {
        _handleError(
            'Speech recognition not available for wake word detection');
        return false;
      }

      // Preload activation sound
      await _audioPlayer.setSource(AssetSource(_activationSoundPath));

      _isInitialized = true;
      if (kDebugMode) {
        print('JarvisListener initialized successfully');
      }
      return true;
    } catch (e) {
      _handleError('Wake word listener initialization error: $e');
      return false;
    }
  }

  /// Start listening for wake word in background
  Future<void> startListening() async {
    if (!_isInitialized) {
      _handleError('JarvisListener not initialized');
      return;
    }

    if (_isListening) {
      if (kDebugMode) {
        print('Already listening for wake word');
      }
      return;
    }

    await _startWakeWordDetection();
  }

  /// Internal method to start wake word detection
  Future<void> _startWakeWordDetection() async {
    try {
      _isListening = true;
      onListeningStateChanged?.call(true);

      if (kDebugMode) {
        print('Started listening for wake word: $_wakeWord');
      }

      // Start continuous listening for wake word
      await _speech.listen(
        onResult: (result) => _handleWakeWordResult(result),
        listenFor: const Duration(
            minutes: 10), // Long duration for continuous listening
        pauseFor: const Duration(seconds: 10), // Long pause to keep listening
        localeId: 'en_US',
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.confirmation,
        ),
      );
    } catch (e) {
      _handleError('Start wake word detection error: $e');
      _scheduleRestart();
    }
  }

  /// Handle speech recognition results for wake word detection
  void _handleWakeWordResult(SpeechRecognitionResult result) {
    if (_isActive) {
      // Skip wake word detection when actively processing a command
      return;
    }

    final recognizedWords = result.recognizedWords.toLowerCase();

    if (kDebugMode) {
      print('Wake word detection heard: $recognizedWords');
    }

    // Check if wake word is detected
    if (_containsWakeWord(recognizedWords)) {
      if (kDebugMode) {
        print('🎯 Wake word detected: JARVIS');
      }

      _onWakeWordDetected();
    }
  }

  /// Check if the recognized text contains the wake word
  bool _containsWakeWord(String text) {
    final lowerText = text.toLowerCase().trim();

    // Check exact match and variants
    for (final variant in _wakeWordVariants) {
      if (lowerText.contains(variant)) {
        return true;
      }
    }

    // Check for "hey jarvis" or "ok jarvis"
    if (lowerText.contains('hey $_wakeWord') ||
        lowerText.contains('ok $_wakeWord') ||
        lowerText.contains('okay $_wakeWord')) {
      return true;
    }

    return false;
  }

  /// Called when wake word is detected
  Future<void> _onWakeWordDetected() async {
    if (_isActive) return; // Prevent multiple triggers

    _isActive = true;

    try {
      // Stop wake word listening temporarily
      await _speech.stop();
      _isListening = false;
      onListeningStateChanged?.call(false);

      // Play activation sound
      await _playActivationSound();

      // Notify callback
      onWakeWordDetected?.call();

      // Start idle timer to return to wake word detection
      _startIdleTimer();
    } catch (e) {
      _handleError('Wake word detection callback error: $e');
      await returnToIdle();
    }
  }

  /// Play activation sound
  Future<void> _playActivationSound() async {
    try {
      await _audioPlayer.resume();
      if (kDebugMode) {
        print('Playing activation sound');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Activation sound error: $e');
      }
      // Non-critical error, continue
    }
  }

  /// Start idle timer to return to wake word detection after inactivity
  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, () {
      if (kDebugMode) {
        print('Idle timeout - returning to wake word detection');
      }
      returnToIdle();
    });
  }

  /// Reset idle timer (call this when user is actively speaking)
  void resetIdleTimer() {
    if (_isActive) {
      _startIdleTimer();
    }
  }

  /// Return to idle state and resume wake word detection
  Future<void> returnToIdle() async {
    if (!_isActive) return;

    _idleTimer?.cancel();
    _isActive = false;

    if (kDebugMode) {
      print('Returning to idle - resuming wake word detection');
    }

    onReturnToIdle?.call();

    // Resume wake word detection
    if (_isInitialized) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _startWakeWordDetection();
    }
  }

  /// Stop listening for wake word
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      _idleTimer?.cancel();
      _restartTimer?.cancel();

      await _speech.stop();
      _isListening = false;
      _isActive = false;
      onListeningStateChanged?.call(false);

      if (kDebugMode) {
        print('Stopped wake word detection');
      }
    } catch (e) {
      _handleError('Stop wake word detection error: $e');
    }
  }

  /// Handle status changes from speech recognition
  void _handleStatusChange(String status) {
    if (kDebugMode) {
      print('Wake word detection status: $status');
    }

    // Auto-restart if speech recognition stops unexpectedly
    if (status == 'done' || status == 'notListening') {
      if (_isListening && !_isActive) {
        _scheduleRestart();
      }
    }
  }

  /// Handle speech errors
  void _handleSpeechError(String error) {
    if (kDebugMode) {
      print('Wake word detection speech error: $error');
    }

    // Don't report minor errors, just restart
    if (!error.contains('network')) {
      _scheduleRestart();
    }
  }

  /// Schedule automatic restart of wake word detection
  void _scheduleRestart() {
    if (!_isInitialized || _isActive) return;

    _restartTimer?.cancel();
    _restartTimer = Timer(_restartDelay, () {
      if (_isInitialized && !_isActive) {
        if (kDebugMode) {
          print('Auto-restarting wake word detection');
        }
        _startWakeWordDetection();
      }
    });
  }

  /// Handle errors
  void _handleError(String error) {
    if (kDebugMode) {
      print('JarvisListener Error: $error');
    }
    onError?.call(error);
  }

  /// Check if currently listening for wake word
  bool get isListening => _isListening;

  /// Check if wake word was detected and processing command
  bool get isActive => _isActive;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    _idleTimer?.cancel();
    _restartTimer?.cancel();
    _speech.stop();
    _audioPlayer.dispose();
    _isListening = false;
    _isActive = false;
    _isInitialized = false;

    if (kDebugMode) {
      print('JarvisListener disposed');
    }
  }
}
