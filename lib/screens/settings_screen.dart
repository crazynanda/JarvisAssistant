import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:provider/provider.dart';
import '../services/elevenlabs_service.dart';
import '../widgets/theme_selector.dart';
import '../themes/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  final bool wakeWordEnabled;
  final Function(bool) onWakeWordToggle;

  const SettingsScreen({
    super.key,
    required this.wakeWordEnabled,
    required this.onWakeWordToggle,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _wakeWordEnabled;
  late bool _webInternetEnabled;
  late bool _filesMediaEnabled;
  late bool _messagesEnabled;
  late bool _contactsEnabled;
  late bool _sensorsEnabled;

  final ElevenLabsService _elevenLabs = ElevenLabsService();
  bool _elevenLabsEnabled = false;
  String? _selectedVoiceName;

  @override
  void initState() {
    super.initState();
    _wakeWordEnabled = widget.wakeWordEnabled;
    _loadPermissions();
    _loadElevenLabsSettings();
  }

  Future<void> _loadElevenLabsSettings() async {
    await _elevenLabs.initialize();
    setState(() {
      _elevenLabsEnabled = _elevenLabs.isEnabled;
      _selectedVoiceName = _elevenLabs.currentVoiceName;
    });
  }

  Future<void> _loadPermissions() async {
    final webInternet = await SettingsManager.getPermission('web_internet');
    final filesMedia = await SettingsManager.getPermission('files_media');
    final messages = await SettingsManager.getPermission('messages');
    final contacts = await SettingsManager.getPermission('contacts');
    final sensors = await SettingsManager.getPermission('sensors');

    setState(() {
      _webInternetEnabled = webInternet;
      _filesMediaEnabled = filesMedia;
      _messagesEnabled = messages;
      _contactsEnabled = contacts;
      _sensorsEnabled = sensors;
    });
  }

  Future<void> _testMicrophone() async {
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Microphone permission denied.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E2749),
          title: const Row(
            children: [
              Icon(Icons.mic, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Testing Microphone', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF00A8E8)),
              SizedBox(height: 20),
              Text('Speak now...', style: TextStyle(color: Colors.white70)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    final speech = SpeechToText();
    bool isAvailable = await speech.initialize(
      onError: (error) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Speech error: ${error.errorMsg}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Microphone test completed!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      },
    );

    if (!isAvailable) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await speech.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Heard: "${result.recognizedWords}"'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      },
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.theme;

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: AppBar(
            backgroundColor: theme.headerColor,
            title: Text('Settings',
                style: TextStyle(color: theme.headerTextColor)),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.headerTextColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Voice', theme.accentColor),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  icon: Icons.mic,
                  title: 'Test Microphone',
                  subtitle: 'Test speech recognition',
                  trailing: Icon(Icons.chevron_right,
                      color: theme.secondaryTextColor),
                  onTap: _testMicrophone,
                  surfaceColor: theme.surfaceColor,
                  textColor: theme.textColor,
                  secondaryColor: theme.secondaryTextColor,
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('Voice (AI)', theme.accentColor),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  icon: Icons.record_voice_over,
                  title: 'AI Voice',
                  subtitle: _elevenLabsEnabled
                      ? 'Using AI voice'
                      : 'Using device voice',
                  trailing: Switch(
                    value: _elevenLabsEnabled,
                    onChanged: (value) async {
                      if (value && !_elevenLabs.isConfigured) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Configure ElevenLabs API key first')),
                        );
                        return;
                      }
                      await _elevenLabs.setEnabled(value);
                      setState(() {
                        _elevenLabsEnabled = value;
                      });
                    },
                    activeColor: theme.accentColor,
                  ),
                  onTap: () {},
                  surfaceColor: theme.surfaceColor,
                  textColor: theme.textColor,
                  secondaryColor: theme.secondaryTextColor,
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('Permissions', theme.accentColor),
                const SizedBox(height: 12),
                _buildPermissionToggle(
                  icon: Icons.language,
                  title: 'Web/Internet',
                  subtitle: 'Allow web search and online data',
                  value: _webInternetEnabled,
                  onChanged: (value) async {
                    setState(() => _webInternetEnabled = value);
                    await SettingsManager.setPermission(
                        'web_internet', value);
                  },
                  surfaceColor: theme.surfaceColor,
                  textColor: theme.textColor,
                  secondaryColor: theme.secondaryTextColor,
                  accentColor: theme.accentColor,
                ),
                _buildPermissionToggle(
                  icon: Icons.folder,
                  title: 'Files/Media',
                  subtitle: 'Allow file and image analysis',
                  value: _filesMediaEnabled,
                  onChanged: (value) async {
                    setState(() => _filesMediaEnabled = value);
                    await SettingsManager.setPermission(
                        'files_media', value);
                  },
                  surfaceColor: theme.surfaceColor,
                  textColor: theme.textColor,
                  secondaryColor: theme.secondaryTextColor,
                  accentColor: theme.accentColor,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final status =
                          await Permission.microphone.request();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              status.isGranted
                                  ? 'Microphone permission granted!'
                                  : 'Microphone permission denied.',
                            ),
                            backgroundColor: status.isGranted
                                ? Colors.green
                                : Colors.red,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.mic,
                        color: theme.textColor),
                    label: Text('Request Microphone Permission',
                        style: TextStyle(color: theme.textColor)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('App Theme', theme.accentColor),
                const SizedBox(height: 12),
                const ThemeSelector(),
                const SizedBox(height: 32),
                _buildSectionHeader('About', theme.accentColor),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: 'J.A.R.V.I.S.',
                  subtitle: 'Version 1.0.0',
                  onTap: () {},
                  surfaceColor: theme.surfaceColor,
                  textColor: theme.textColor,
                  secondaryColor: theme.secondaryTextColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color accentColor) {
    return Text(
      title,
      style: TextStyle(
        color: accentColor,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    Color surfaceColor = const Color(0xFF1E2749),
    Color textColor = Colors.white,
    Color secondaryColor = Colors.white54,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: secondaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(color: textColor, fontSize: 16)),
                  Text(subtitle,
                      style:
                          TextStyle(color: secondaryColor, fontSize: 12)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    Color surfaceColor = const Color(0xFF1E2749),
    Color textColor = Colors.white,
    Color secondaryColor = Colors.white54,
    Color accentColor = const Color(0xFF00A8E8),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: secondaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(color: textColor, fontSize: 16)),
                Text(subtitle,
                    style:
                        TextStyle(color: secondaryColor, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: accentColor,
          ),
        ],
      ),
    );
  }

  Future<void> _testElevenLabsVoice() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playing voice sample...')),
      );
      await _elevenLabs.testVoice();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class SettingsManager {
  static const String _wakeWordKey = 'wake_word_enabled';

  static Future<bool> getWakeWordEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wakeWordKey) ?? true;
  }

  static Future<void> setWakeWordEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wakeWordKey, enabled);
  }

  static Future<bool> getPermission(String permission) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'permission_$permission';
    return prefs.getBool(key) ?? true;
  }

  static Future<void> setPermission(String permission, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'permission_$permission';
    await prefs.setBool(key, enabled);
  }

  static Future<Map<String, bool>> getAllPermissions() async {
    return {
      'web_internet': await getPermission('web_internet'),
      'files_media': await getPermission('files_media'),
      'messages': await getPermission('messages'),
      'contacts': await getPermission('contacts'),
      'sensors': await getPermission('sensors'),
    };
  }
}
