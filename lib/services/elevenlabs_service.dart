import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// ElevenLabs Text-to-Speech Service (Backend Proxy)
/// Routes TTS requests through the backend for secure API key handling
class ElevenLabsService {
  // Backend URL (same as main API)
  static const String _defaultBackendUrl =
      'https://jarvis-api-bovo.onrender.com';

  // Preference keys
  static const String _enabledPref = 'elevenlabs_enabled';
  static const String _voiceNamePref = 'elevenlabs_voice_name';

  // Audio player for playback
  final AudioPlayer _audioPlayer = AudioPlayer();

  // State
  String _backendUrl = _defaultBackendUrl;
  bool _isEnabled = true; // Enabled by default since using backend
  bool _isSpeaking = false;
  String _currentVoice = 'Adam';

  // Popular preset voices (fallback)
  static const List<Map<String, String>> presetVoices = [
    {
      'id': 'pNInz6obpgDQGcFmaJgB',
      'name': 'Adam',
      'description': 'Deep male voice'
    },
    {
      'id': 'ErXwobaYiN019PkySvjV',
      'name': 'Antoni',
      'description': 'Young male voice'
    },
    {
      'id': '21m00Tcm4TlvDq8ikWAM',
      'name': 'Rachel',
      'description': 'Female voice'
    },
    {
      'id': 'AZnzlk1XvdvUeBnXmlld',
      'name': 'Domi',
      'description': 'Female, young'
    },
    {
      'id': 'EXAVITQu4vr4xnSDxMaL',
      'name': 'Bella',
      'description': 'Female, soft'
    },
    {
      'id': 'MF3mGyEYCl7XYWbV9V6O',
      'name': 'Elli',
      'description': 'Female, young'
    },
    {'id': 'TxGEqnHWrfWFTfGW9XjX', 'name': 'Josh', 'description': 'Male, deep'},
    {
      'id': 'VR6AewLTigWG4xSOukaG',
      'name': 'Arnold',
      'description': 'Male, crisp'
    },
    {'id': 'yoZ06aMxZJJ28mfd3POQ', 'name': 'Sam', 'description': 'Male, raspy'},
  ];

  /// Initialize the service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_enabledPref) ?? true; // Enabled by default
    _currentVoice = prefs.getString(_voiceNamePref) ?? 'Adam';

    // Get backend URL from saved preferences
    final savedUrl = prefs.getString('server_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _backendUrl = savedUrl;
    }

    // Set up audio player completion handler
    _audioPlayer.onPlayerComplete.listen((_) {
      _isSpeaking = false;
    });

    // Try to fetch voices from backend
    await _fetchVoicesFromBackend();

    if (kDebugMode) {
      print(
          'ElevenLabs (Backend Proxy) initialized: enabled=$_isEnabled, voice=$_currentVoice');
    }
  }

  /// Fetch available voices from backend
  Future<void> _fetchVoicesFromBackend() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_backendUrl/voices'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Backend returns voices, could parse and use them
        if (kDebugMode) {
          print('Voices available from backend');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Could not fetch voices from backend: $e');
      }
    }
  }

  /// Check if service is enabled
  bool get isConfigured => true; // Always configured when using backend
  bool get isEnabled => _isEnabled;
  bool get isSpeaking => _isSpeaking;
  String? get currentVoiceId => null; // Not needed with backend proxy
  String? get currentVoiceName => _currentVoice;

  /// No API key needed - handled by backend
  String? getApiKeyMasked() => 'Backend Proxy';

  /// Enable/disable ElevenLabs
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledPref, enabled);
  }

  /// Set voice (by name)
  Future<void> setVoice(String voiceId, String voiceName) async {
    _currentVoice = voiceName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_voiceNamePref, voiceName);
  }

  /// Speak text using backend TTS proxy
  Future<void> speak(String text) async {
    if (!_isEnabled) {
      throw Exception('ElevenLabs not enabled');
    }

    if (text.isEmpty) return;

    // Limit text length
    if (text.length > 1000) {
      text = text.substring(0, 1000);
    }

    try {
      _isSpeaking = true;

      // Call backend /speak endpoint
      final response = await http
          .post(
            Uri.parse('$_backendUrl/speak'),
            headers: {
              'Content-Type': 'application/json',
            },
            body:
                '{"text": "${text.replaceAll('"', '\\"').replaceAll('\n', ' ')}", "voice": "$_currentVoice"}',
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // Save audio to temp file and play
        final tempDir = await getTemporaryDirectory();
        final audioFile = File('${tempDir.path}/tts_output.mp3');
        await audioFile.writeAsBytes(response.bodyBytes);

        await _audioPlayer.play(DeviceFileSource(audioFile.path));

        if (kDebugMode) {
          print('ElevenLabs (Backend): Playing audio');
        }
      } else if (response.statusCode == 503) {
        _isSpeaking = false;
        throw Exception('TTS service not configured on server');
      } else {
        _isSpeaking = false;
        throw Exception('TTS failed: ${response.statusCode}');
      }
    } catch (e) {
      _isSpeaking = false;
      if (kDebugMode) {
        print('ElevenLabs speak error: $e');
      }
      rethrow;
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    await _audioPlayer.stop();
    _isSpeaking = false;
  }

  /// Test the voice with a sample
  Future<void> testVoice() async {
    await speak(
        "Hello sir, I am JARVIS, your personal assistant. How may I help you today?");
  }

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
