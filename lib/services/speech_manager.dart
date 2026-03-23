import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// SpeechManager - Shared speech recognition manager
/// Prevents multiple SpeechToText instances from conflicting
class SpeechManager {
  static final SpeechManager _instance = SpeechManager._internal();
  factory SpeechManager() => _instance;
  SpeechManager._internal();

  // Shared SpeechToText instance
  final SpeechToText _speech = SpeechToText();
  
  // State management
  bool _isInitialized = false;
  bool _isListening = false;
  String? _currentOwner; // 'voice' or 'wake_word'
  Timer? _timeoutTimer;
  
  // Callbacks
  Function(String owner)? onOwnershipChanged;
  Function(String error)? onError;
  
  // Configuration
  static const Duration _ownershipTimeout = Duration(seconds: 30);

  /// Initialize the shared speech manager
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      final available = await _speech.initialize(
        onError: (error) => _handleSpeechError(error.errorMsg),
        onStatus: (status) => _handleStatusChange(status),
      );
      
      if (available) {
        _isInitialized = true;
        if (kDebugMode) {
          print('SpeechManager initialized successfully');
        }
        return true;
      } else {
        _handleError('Speech recognition not available on this device');
        return false;
      }
    } catch (e) {
      _handleError('SpeechManager initialization error: $e');
      return false;
    }
  }

  /// Request ownership of speech recognition
  /// Returns true if ownership granted
  Future<bool> requestOwnership(String owner) async {
    if (!_isInitialized) {
      _handleError('SpeechManager not initialized');
      return false;
    }
    
    if (_isListening && _currentOwner != owner) {
      // Current owner is different - need to wait or force
      if (kDebugMode) {
        print('SpeechManager: $owner requesting ownership while $_currentOwner is using');
      }
      return false;
    }
    
    _currentOwner = owner;
    onOwnershipChanged?.call(owner);
    
    if (kDebugMode) {
      print('SpeechManager: Ownership granted to $owner');
    }
    
    // Reset timeout
    _resetTimeout();
    
    return true;
  }

  /// Release ownership
  void releaseOwnership(String owner) {
    if (_currentOwner == owner) {
      _currentOwner = null;
      _stopTimeout();
      onOwnershipChanged?.call('');
      
      if (kDebugMode) {
        print('SpeechManager: Ownership released by $owner');
      }
    }
  }

  /// Start listening with ownership check
  Future<void> listen({
    required String owner,
    required Function(SpeechRecognitionResult) onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    SpeechListenOptions? listenOptions,
  }) async {
    if (!await requestOwnership(owner)) {
      _handleError('Cannot start listening: $owner does not have ownership');
      return;
    }
    
    if (_isListening) {
      await stopListening(owner);
    }
    
    _isListening = true;
    _resetTimeout();
    
    try {
      await _speech.listen(
        onResult: onResult,
        listenFor: listenFor ?? const Duration(seconds: 30),
        pauseFor: pauseFor ?? const Duration(seconds: 5),
        localeId: localeId ?? 'en_US',
        listenOptions: listenOptions ?? SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
      );
      
      if (kDebugMode) {
        print('SpeechManager: $owner started listening');
      }
    } catch (e) {
      _handleError('SpeechManager listen error: $e');
      _isListening = false;
      releaseOwnership(owner);
    }
  }

  /// Stop listening
  Future<void> stopListening(String owner) async {
    if (_currentOwner != owner) {
      if (kDebugMode) {
        print('SpeechManager: $owner cannot stop (not current owner)');
      }
      return;
    }
    
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      _stopTimeout();
      
      if (kDebugMode) {
        print('SpeechManager: $owner stopped listening');
      }
    }
  }

  /// Check if speech recognition is available
  bool get isAvailable => _isInitialized && !_isListening;
  
  /// Check if currently listening
  bool get isListening => _isListening;
  
  /// Get current owner
  String? get currentOwner => _currentOwner;

  void _resetTimeout() {
    _stopTimeout();
    _timeoutTimer = Timer(_ownershipTimeout, () {
      if (_isListening) {
        if (kDebugMode) {
          print('SpeechManager: Ownership timeout for $_currentOwner');
        }
        stopListening(_currentOwner ?? '');
      }
    });
  }

  void _stopTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  void _handleSpeechError(String error) {
    _isListening = false;
    _currentOwner = null;
    _stopTimeout();
    _handleError('Speech recognition error: $error');
  }

  void _handleStatusChange(String status) {
    if (kDebugMode) {
      print('SpeechManager status: $status');
    }
    
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      _currentOwner = null;
      _stopTimeout();
    }
  }

  void _handleError(String error) {
    if (kDebugMode) {
      print('SpeechManager error: $error');
    }
    onError?.call(error);
  }

  /// Cleanup resources
  void dispose() {
    _stopTimeout();
    _speech.cancel();
    _isInitialized = false;
    _isListening = false;
    _currentOwner = null;
    
    if (kDebugMode) {
      print('SpeechManager disposed');
    }
  }
}