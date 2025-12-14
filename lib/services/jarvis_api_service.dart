import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/settings_screen.dart';

class JarvisApiService {
  String _baseUrl;

  // Default URLs for different platforms
  static const String defaultEmulatorUrl = 'http://10.0.2.2:8000';
  static const String defaultLocalUrl = 'http://localhost:8000';

  // Your local network IP - users can configure this in settings
  static const String defaultLocalNetworkUrl =
      'https://jarvis-api-bovo.onrender.com';

  JarvisApiService({String? baseUrl})
      : _baseUrl = baseUrl ??
            (kIsWeb
                ? defaultLocalUrl
                : (Platform.isAndroid
                    ? defaultLocalNetworkUrl // Use local network by default for physical devices
                    : defaultLocalUrl));

  String get baseUrl => _baseUrl;

  /// Update the server URL (for settings)
  Future<void> setServerUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jarvis_server_url', url);
  }

  /// Load server URL from settings
  Future<void> loadServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('jarvis_server_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
    }
  }

  /// Get saved server URL
  static Future<String?> getSavedServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jarvis_server_url');
  }

  /// Test connection to server
  Future<bool> testConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/health'),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Send message to J.A.R.V.I.S with permissions
  Future<String> ask(String userInput) async {
    try {
      // Get current permissions
      final permissions = await SettingsManager.getAllPermissions();

      // Send request with permissions (90 second timeout for cold starts)
      final response = await http
          .post(
            Uri.parse('$_baseUrl/ask'),
            headers: {
              'Content-Type': 'application/json',
              'X-Permissions': json.encode(permissions),
            },
            body: json.encode({
              'user_input': userInput,
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to get response');
      }
    } catch (e) {
      throw Exception('Error communicating with J.A.R.V.I.S: $e');
    }
  }
}
