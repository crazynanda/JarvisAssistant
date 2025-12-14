import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing background wake word detection
/// Communicates with native Android WakeWordService
class WakeWordManager {
  static const _methodChannel = MethodChannel('com.jarvis/wake_word');
  static const _eventChannel = EventChannel('com.jarvis/wake_word_events');

  static WakeWordManager? _instance;
  static WakeWordManager get instance => _instance ??= WakeWordManager._();

  WakeWordManager._();

  StreamSubscription? _eventSubscription;
  final _wakeWordController = StreamController<void>.broadcast();

  /// Stream that emits when wake word is detected
  Stream<void> get onWakeWordDetected => _wakeWordController.stream;

  /// Whether background listening is currently active
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// Initialize the wake word manager
  Future<void> initialize() async {
    // Listen for wake word events from native
    _eventSubscription =
        _eventChannel.receiveBroadcastStream().listen(_handleEvent);

    // Check if service was running
    _isRunning = await _checkServiceRunning();

    // Check if app was launched by wake word
    final wasLaunched = await wasLaunchedByWakeWord();
    if (wasLaunched) {
      // Notify listeners that wake word was detected
      _wakeWordController.add(null);
    }
  }

  /// Start background wake word listening
  /// Requires Picovoice access key from https://console.picovoice.ai/
  Future<bool> startListening(String accessKey) async {
    if (accessKey.isEmpty) {
      throw Exception('Picovoice access key is required');
    }

    try {
      // Save access key for persistence
      await _saveAccessKey(accessKey);

      // Start native service
      await _methodChannel.invokeMethod('startWakeWordService', {
        'accessKey': accessKey,
      });

      _isRunning = true;
      return true;
    } on PlatformException catch (e) {
      debugPrint('Failed to start wake word service: ${e.message}');
      return false;
    }
  }

  /// Stop background wake word listening
  Future<bool> stopListening() async {
    try {
      await _methodChannel.invokeMethod('stopWakeWordService');
      _isRunning = false;
      return true;
    } on PlatformException catch (e) {
      debugPrint('Failed to stop wake word service: ${e.message}');
      return false;
    }
  }

  /// Check if app was launched by wake word detection
  Future<bool> wasLaunchedByWakeWord() async {
    try {
      return await _methodChannel.invokeMethod('wasLaunchedByWakeWord') ??
          false;
    } on PlatformException {
      return false;
    }
  }

  /// Get saved access key
  Future<String?> getSavedAccessKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('picovoice_access_key');
  }

  /// Save access key for persistence
  Future<void> _saveAccessKey(String accessKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('picovoice_access_key', accessKey);

    // Also save to native side
    await _methodChannel.invokeMethod('saveAccessKey', {
      'accessKey': accessKey,
    });
  }

  Future<bool> _checkServiceRunning() async {
    try {
      return await _methodChannel.invokeMethod('isServiceRunning') ?? false;
    } on PlatformException {
      return false;
    }
  }

  void _handleEvent(dynamic event) {
    if (event is Map && event['event'] == 'wake_word_detected') {
      debugPrint('Wake word detected!');
      _wakeWordController.add(null);
    }
  }

  /// Dispose resources
  void dispose() {
    _eventSubscription?.cancel();
    _wakeWordController.close();
  }
}
