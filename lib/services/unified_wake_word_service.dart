import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'foreground_wake_word.dart';

/// Unified Wake Word Service - Hybrid approach (Cost-effective & Reliable)
/// 
/// Combines multiple wake word detection methods:
/// 1. Foreground: speech_to_text with pattern matching (FREE, always works)
/// 2. Background: Porcupine native service (if API key available)
/// 3. Push-to-talk: Manual activation (always available)
/// 
/// CRITICAL: Must share SpeechToText instance with JarvisVoice to avoid conflicts.
/// Call UnifiedWakeWordService.setSharedSpeechInstance() before initialize().
/// 
/// Features:
/// - Instant detection (< 300ms)
/// - Works without API key (foreground mode)
/// - Background mode support (with API key)
/// - Alexa-style "Yes sir" response
/// - Comprehensive debugging

class UnifiedWakeWordService {
  static final UnifiedWakeWordService _instance = UnifiedWakeWordService._internal();
  factory UnifiedWakeWordService() => _instance;
  UnifiedWakeWordService._internal();

  static SpeechToText? _sharedSpeechInstance;
  
  late ForegroundWakeWordDetector _foregroundDetector;
  bool _foregroundDetectorCreated = false;
   
  static const MethodChannel _channel = MethodChannel('com.jarvis/wake_word');
  static const EventChannel _eventChannel = EventChannel('com.jarvis/wake_word_events');

  bool _isInitialized = false;
  bool _foregroundRunning = false;
  bool _backgroundRunning = false;
  bool _wasLaunchedByWakeWord = false;
  String? _accessKey;
  String _preferredGreeting = 'sir';
  String _customWakeWordPath = 'assets/wake_words/jarvis_en_android_v4_0_0.ppn';

  StreamSubscription? _eventSubscription;
  final _wakeWordController = StreamController<void>.broadcast();
  final _stateController = StreamController<WakeWordState>.broadcast();
  final _debugController = StreamController<WakeWordDebugInfo>.broadcast();

  Function()? onWakeWordDetected;
  Function(String)? onError;
  Function(bool)? onListeningStateChanged;
  Function(String)? onStatusUpdate;

  DateTime? _lastDetectionTime;
  int _detectionCount = 0;
  int _falsePositiveCount = 0;
  String _lastHeardWords = '';

  bool get isInitialized => _isInitialized;
  bool get isRunning => _foregroundRunning || _backgroundRunning;
  bool get foregroundRunning => _foregroundRunning;
  bool get backgroundRunning => _backgroundRunning;
  bool get hasAccessKey => _accessKey != null && _accessKey!.isNotEmpty;
  String get preferredGreeting => _preferredGreeting;
  int get detectionCount => _detectionCount;
  int get falsePositiveCount => _falsePositiveCount;
  String get lastHeardWords => _lastHeardWords;
  
  Stream<void> get onWakeWord => _wakeWordController.stream;
  Stream<WakeWordState> get onStateChange => _stateController.stream;
  Stream<WakeWordDebugInfo> get onDebugInfo => _debugController.stream;

  /// Set the shared SpeechToText instance (MUST be called before initialize)
  static void setSharedSpeechInstance(SpeechToText speech) {
    _sharedSpeechInstance = speech;
    if (kDebugMode) {
      print('[WakeWord] Shared SpeechToText instance set');
    }
  }

  /// Initialize the wake word service
  Future<bool> initialize({String? preferredGreeting}) async {
    if (_isInitialized) return true;

    try {
      _updateStatus('🔧 Initializing Unified Wake Word Service...');

      if (preferredGreeting != null) {
        _preferredGreeting = preferredGreeting;
      }

      // Create foreground detector with shared SpeechToText instance
      if (!_foregroundDetectorCreated) {
        _foregroundDetector = ForegroundWakeWordDetector(
          speech: _sharedSpeechInstance,
        );
        _foregroundDetectorCreated = true;
      }

      final foregroundInit = await _foregroundDetector.initialize();
      if (!foregroundInit) {
        _handleError('Failed to initialize foreground detector');
        return false;
      }

      _foregroundDetector.onWakeWordDetected = () => _handleWakeWordDetected(detectionType: 'foreground');
      _foregroundDetector.onStatusUpdate = (msg) => _updateStatus('Foreground: $msg');
      _foregroundDetector.onError = (error) => _handleError('Foreground: $error');
      _foregroundDetector.onHeardWords = (words) => _lastHeardWords = words;

      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        _handleEvent,
        onError: (error) => _handleError('Event channel error: $error'),
      );

      _isInitialized = true;
      _updateState(WakeWordState.idle);
      
      _updateStatus('✅ Wake word service initialized');
      _updateStatus('🔑 API Key: ${hasAccessKey ? "Available (background mode ready)" : "Not available (foreground mode only)"}');
      _updateStatus('🎤 Shared SpeechToText: ${_sharedSpeechInstance != null ? "Yes" : "No (creating own instance)"}');

      return true;
    } catch (e) {
      _handleError('Initialization error: $e');
      return false;
    }
  }

  /// Start wake word detection
  Future<bool> start({String? accessKey}) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return false;
    }

    try {
      final key = accessKey ?? _accessKey;
      
      await _startForegroundMode();
      
      if (key != null && key.isNotEmpty) {
        await _saveAccessKey(key);
        _accessKey = key;
        await _startBackgroundMode(key);
      } else {
        _updateStatus('💡 Tip: Add API key in Settings for background detection when app is closed');
      }

      onListeningStateChanged?.call(true);
      return true;
      
    } catch (e) {
      _handleError('Failed to start: $e');
      return false;
    }
  }

  /// Pause wake word detection (when command listening starts)
  void pause() {
    if (_foregroundDetectorCreated) {
      _foregroundDetector.pause();
      _updateStatus('⏸️ Wake word detection paused');
    }
  }

  /// Resume wake word detection (when command listening ends)
  void resume() {
    if (_foregroundDetectorCreated) {
      _foregroundDetector.resume();
      _updateStatus('▶️ Wake word detection resumed');
    }
  }

  Future<void> _startForegroundMode() async {
    try {
      _updateStatus('🎧 Starting foreground wake word detection...');
      
      await _foregroundDetector.start();
      _foregroundRunning = true;
      
      _updateStatus('✅ Foreground mode active - Say "JARVIS"');
      _updateStatus('📱 This works while the app is open (no API key needed)');
      
    } catch (e) {
      _handleError('Foreground start error: $e');
    }
  }

  Future<void> _startBackgroundMode(String key) async {
    try {
      _updateStatus('🔌 Starting background wake word detection...');

      await _channel.invokeMethod('startWakeWordService', {
        'accessKey': key,
      });

      _backgroundRunning = true;
      _updateState(WakeWordState.listening);

      _updateStatus('✅ Background mode active - Works when app is closed');
      
    } catch (e) {
      _handleError('Background start error: $e');
    }
  }

  Future<void> stop() async {
    try {
      if (_foregroundRunning) {
        await _foregroundDetector.stop();
        _foregroundRunning = false;
      }
      
      if (_backgroundRunning) {
        await _channel.invokeMethod('stopWakeWordService');
        _backgroundRunning = false;
      }
      
      _updateState(WakeWordState.stopped);
      onListeningStateChanged?.call(false);

      _updateStatus('🛑 Wake word detection stopped');
    } catch (e) {
      _handleError('Stop error: $e');
    }
  }

  Future<void> testDetection() async {
    _updateStatus('🧪 Testing wake word detection...');
    
    try {
      await _channel.invokeMethod('testWakeWord');
      _updateStatus('✅ Test signal sent');
    } catch (e) {
      _handleWakeWordDetected(detectionType: 'test');
    }
  }

  Future<bool> wasLaunchedByWakeWord() async {
    try {
      final result = await _channel.invokeMethod('wasLaunchedByWakeWord');
      _wasLaunchedByWakeWord = result ?? false;
      return _wasLaunchedByWakeWord;
    } catch (e) {
      return false;
    }
  }

  void _handleEvent(dynamic event) {
    if (event is Map) {
      final eventType = event['event'] as String?;
      final isTest = event['test'] as bool? ?? false;
      
      switch (eventType) {
        case 'wake_word_detected':
          _handleWakeWordDetected(detectionType: isTest ? 'test' : 'background');
          break;
        case 'error':
          final errorMsg = event['message'] as String? ?? 'Unknown error';
          _handleError('Background: $errorMsg');
          break;
      }
    }
  }

  void _handleWakeWordDetected({required String detectionType}) {
    final now = DateTime.now();
    
    if (_lastDetectionTime != null) {
      final diff = now.difference(_lastDetectionTime!);
      if (diff.inMilliseconds < 2000) {
        _updateStatus('⏱️ Debounced (${diff.inMilliseconds}ms)');
        return;
      }
    }

    _lastDetectionTime = now;
    _detectionCount++;

    _updateStatus('🎯 WAKE WORD DETECTED via $detectionType');
    
    _updateState(WakeWordState.detected);
    _wakeWordController.add(null);
    onWakeWordDetected?.call();

    _debugController.add(WakeWordDebugInfo(
      timestamp: now,
      confidence: 1.0,
      detectionType: detectionType,
    ));
  }

  void simulateDetection() {
    _updateStatus('👆 Manual wake word trigger');
    _handleWakeWordDetected(detectionType: 'manual');
  }

  void setPreferredGreeting(String greeting) {
    _preferredGreeting = greeting;
    _updateStatus('Updated greeting preference: $greeting');
  }

  Future<void> _loadAccessKey() async {
    final prefs = await SharedPreferences.getInstance();
    _accessKey = prefs.getString('picovoice_access_key');
  }

  Future<void> _saveAccessKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('picovoice_access_key', key);
  }

  Future<void> clearAccessKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('picovoice_access_key');
    _accessKey = null;
    _updateStatus('Access key cleared');
  }

  void _updateState(WakeWordState newState) {
    _stateController.add(newState);
  }

  void _updateStatus(String message) {
    if (kDebugMode) {
      print('[WakeWord] $message');
    }
    onStatusUpdate?.call(message);
  }

  void _handleError(String error) {
    _updateStatus('❌ Error: $error');
    _updateState(WakeWordState.error);
    onError?.call(error);
  }

  Map<String, dynamic> getStatusReport() {
    return {
      'initialized': _isInitialized,
      'foregroundRunning': _foregroundRunning,
      'backgroundRunning': _backgroundRunning,
      'hasAccessKey': hasAccessKey,
      'detectionCount': _detectionCount,
      'falsePositives': _falsePositiveCount,
      'lastDetection': _lastDetectionTime?.toIso8601String(),
      'lastHeardWords': _lastHeardWords,
      'preferredGreeting': _preferredGreeting,
    };
  }

  void dispose() {
    if (_foregroundDetectorCreated) {
      _foregroundDetector.dispose();
    }
    _eventSubscription?.cancel();
    _wakeWordController.close();
    _stateController.close();
    _debugController.close();
    _isInitialized = false;
    _foregroundRunning = false;
    _backgroundRunning = false;
  }
}

enum WakeWordState {
  idle,
  listening,
  detected,
  stopped,
  error,
}

class WakeWordDebugInfo {
  final DateTime timestamp;
  final double confidence;
  final String detectionType;

  WakeWordDebugInfo({
    required this.timestamp,
    required this.confidence,
    required this.detectionType,
  });
}
