import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../screens/settings_screen.dart';

class JarvisApiService {
  final String baseUrl;

  JarvisApiService({String? baseUrl})
      : baseUrl = baseUrl ??
            (kIsWeb
                ? 'http://localhost:8000'
                : (Platform.isAndroid
                    ? 'http://10.0.2.2:8000'
                    : 'http://localhost:8000'));

  /// Send message to J.A.R.V.I.S with permissions
  Future<String> ask(String userInput) async {
    try {
      // Get current permissions
      final permissions = await SettingsManager.getAllPermissions();

      // Send request with permissions
      final response = await http.post(
        Uri.parse('$baseUrl/ask'),
        headers: {
          'Content-Type': 'application/json',
          'X-Permissions': json.encode(permissions),
        },
        body: json.encode({
          'user_input': userInput,
        }),
      );

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
