import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class ForegroundWakeWordDetector {
  final SpeechToText _speech;
  final bool _ownsSpeechInstance;
  
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isRunning = false;
  bool _isPaused = false;
  DateTime? _lastDetectionTime;
  
  ForegroundWakeWordDetector({SpeechToText? speech})
      : _speech = speech ?? SpeechToText(),
        _ownsSpeechInstance = speech == null;
  
  static const Duration _debounceWindow = Duration(seconds: 2);
  static const Duration _listenDuration = Duration(seconds: 4);
  static const Duration _pauseDuration = Duration(seconds: 1);
  static const String _locale = 'en_US';
  
  final List<String> _wakeWordPatterns = [
    'jarvis',
    'jar vis',
    'jarvice',
    'jervis',
    'jarviss',
    'jarvus',
    'hey jarvis',
    'ok jarvis',
    'okay jarvis',
    'hi jarvis',
    'hello jarvis',
  ];
  
  Function()? onWakeWordDetected;
  Function(String)? onStatusUpdate;
  Function(String)? onError;
  Function(String)? onHeardWords;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _updateStatus('Initializing foreground wake word detector...');
      debugPrint('[ForegroundWakeWord] Starting initialization...');
      
      if (_ownsSpeechInstance) {
        debugPrint('[ForegroundWakeWord] Initializing own SpeechToText instance...');
        final available = await _speech.initialize(
          onError: (error) => _handleError('Speech error: ${error.errorMsg}'),
          onStatus: (status) => _handleStatus(status),
        );
        debugPrint('[ForegroundWakeWord] SpeechToText initialize result: $available');
        
        if (!available) {
          _handleError('Speech recognition not available');
          return false;
        }
      } else {
        debugPrint('[ForegroundWakeWord] Using shared SpeechToText instance');
        try {
          final locales = await _speech.locales();
          _updateStatus('Using shared SpeechToText (${locales.length} locales)');
        } catch (e) {
          _handleError('Shared SpeechToText not initialized: $e');
          return false;
        }
      }
      
      _isInitialized = true;
      _updateStatus('Foreground wake word detector ready');
      debugPrint('[ForegroundWakeWord] Initialization complete!');
      return true;
      
    } catch (e) {
      _handleError('Initialization error: $e');
      debugPrint('[ForegroundWakeWord] Initialization FAILED: $e');
      return false;
    }
  }
  
  void pause() {
    if (kDebugMode) print('[ForegroundWakeWord] Paused');
    _isPaused = true;
    _speech.stop();
    _isListening = false;
  }
  
  void resume() {
    if (kDebugMode) print('[ForegroundWakeWord] Resumed');
    _isPaused = false;
    if (_isRunning && !_isListening) {
      _startListeningLoop();
    }
  }

  Future<void> start() async {
    if (!_isInitialized) {
      debugPrint('[ForegroundWakeWord] Not initialized, initializing now...');
      final success = await initialize();
      if (!success) {
        debugPrint('[ForegroundWakeWord] Failed to initialize, cannot start');
        return;
      }
    }
    
    if (_isRunning) {
      debugPrint('[ForegroundWakeWord] Already running');
      return;
    }
    
    debugPrint('[ForegroundWakeWord] Starting wake word detection...');
    _isRunning = true;
    _updateStatus('👂 Listening for wake word... Say "JARVIS"');
    debugPrint('[ForegroundWakeWord] Started listening loop');
    _startListeningLoop();
  }

  Future<void> stop() async {
    _isRunning = false;
    _isListening = false;
    try {
      await _speech.stop();
      _updateStatus('Stopped listening');
    } catch (e) {
      _handleError('Stop error: $e');
    }
  }

  Future<void> _startListeningLoop() async {
    debugPrint('[ForegroundWakeWord] Entering listening loop...');
    while (_isRunning && !_isPaused) {
      if (!_isListening && !_isPaused) {
        try {
          _isListening = true;
          
          debugPrint('[ForegroundWakeWord] Starting speech listen...');
          
          await _speech.listen(
            onResult: _handleResult,
            listenFor: _listenDuration,
            pauseFor: _pauseDuration,
            localeId: _locale,
            listenOptions: SpeechListenOptions(
              partialResults: true,
              cancelOnError: false,
              listenMode: ListenMode.dictation,
            ),
          );

          debugPrint('[ForegroundWakeWord] Listen started, waiting...');
          await Future.delayed(const Duration(milliseconds: 1500));
          
        } catch (e) {
          _handleError('Listen error: $e');
          debugPrint('[ForegroundWakeWord] Listen error: $e');
          _isListening = false;
        }
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
    }
    debugPrint('[ForegroundWakeWord] Exiting listening loop');
  }

  void _handleResult(SpeechRecognitionResult result) {
    if (!_isRunning) return;
    
    final text = result.recognizedWords.toLowerCase().trim();
    if (text.isEmpty) return;
    
    debugPrint('[ForegroundWakeWord] Heard: "$text" (confidence: ${result.confidence})');
    onHeardWords?.call(text);
    
    if (_containsWakeWord(text)) {
      debugPrint('[ForegroundWakeWord] WAKE WORD DETECTED! Text: "$text"');
      _processWakeWordDetection(text);
    } else {
      debugPrint('[ForegroundWakeWord] Not a wake word match');
    }
  }

  bool _containsWakeWord(String text) {
    for (final pattern in _wakeWordPatterns) {
      if (text.contains(pattern)) return true;
    }
    return _isPhoneticallySimilar(text, 'jarvis');
  }

  bool _isPhoneticallySimilar(String text, String target) {
    final textConsonants = text.replaceAll(RegExp(r'[aeiou]'), '');
    final targetConsonants = target.replaceAll(RegExp(r'[aeiou]'), '');
    return textConsonants.contains(targetConsonants) || 
           targetConsonants.contains(textConsonants);
  }

  void _processWakeWordDetection(String heardText) {
    final now = DateTime.now();
    
    if (_lastDetectionTime != null) {
      final diff = now.difference(_lastDetectionTime!);
      if (diff < _debounceWindow) {
        if (kDebugMode) print('[ForegroundWakeWord] Debounced');
        return;
      }
    }
    
    _lastDetectionTime = now;
    
    if (kDebugMode) print('[ForegroundWakeWord] WAKE WORD DETECTED: "$heardText"');
    _updateStatus('🎯 Wake word detected!');
    onWakeWordDetected?.call();
  }

  void _handleStatus(String status) {
    if (kDebugMode) print('[ForegroundWakeWord] Status: $status');
    
    if ((status == 'done' || status == 'notListening') && _isRunning) {
      _isListening = false;
    }
  }

  void _updateStatus(String message) {
    if (kDebugMode) print('[WakeWord] $message');
    onStatusUpdate?.call(message);
  }

  void _handleError(String error) {
    if (kDebugMode) print('[ForegroundWakeWord] Error: $error');
    onError?.call(error);
  }

  bool get isInitialized => _isInitialized;
  bool get isRunning => _isRunning;
  bool get isListening => _isListening;
  bool get isPaused => _isPaused;

  void dispose() {
    stop();
    if (_ownsSpeechInstance) _speech.stop();
    _isInitialized = false;
    if (kDebugMode) print('[ForegroundWakeWord] Disposed');
  }
}
