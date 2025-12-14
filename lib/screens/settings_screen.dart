import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/wake_word_manager.dart';
import '../widgets/theme_selector.dart';

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

  // Background wake word
  bool _backgroundWakeWordEnabled = false;
  String _picovoiceAccessKey = '';
  final _accessKeyController = TextEditingController();
  bool _isLoadingBackgroundService = false;

  @override
  void initState() {
    super.initState();
    _wakeWordEnabled = widget.wakeWordEnabled;
    _loadPermissions();
    _loadBackgroundWakeWordSettings();
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

  Future<void> _loadBackgroundWakeWordSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('picovoice_access_key') ?? '';
    final enabled = WakeWordManager.instance.isRunning;

    setState(() {
      _picovoiceAccessKey = key;
      _accessKeyController.text = key;
      _backgroundWakeWordEnabled = enabled;
    });
  }

  Future<void> _toggleBackgroundWakeWord(bool enabled) async {
    if (enabled && _picovoiceAccessKey.isEmpty) {
      _showAccessKeyDialog();
      return;
    }

    setState(() {
      _isLoadingBackgroundService = true;
    });

    try {
      if (enabled) {
        await WakeWordManager.instance.startListening(_picovoiceAccessKey);
      } else {
        await WakeWordManager.instance.stopListening();
      }

      setState(() {
        _backgroundWakeWordEnabled = enabled;
        _isLoadingBackgroundService = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBackgroundService = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle wake word service: $e')),
        );
      }
    }
  }

  void _showAccessKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2749),
        title: const Text(
          'Picovoice Access Key',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get your free access key from:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            const Text(
              'https://console.picovoice.ai/',
              style: TextStyle(color: Color(0xFF00A8E8)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _accessKeyController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter access key',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF0A0E27),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = _accessKeyController.text.trim();
              if (key.isNotEmpty) {
                final navigator = Navigator.of(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('picovoice_access_key', key);
                setState(() {
                  _picovoiceAccessKey = key;
                });
                if (mounted) {
                  navigator.pop();
                  _toggleBackgroundWakeWord(true);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2749),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          _buildSectionHeader('App Theme'),
          const SizedBox(height: 12),

          const ThemeSelector(),
          const SizedBox(height: 32),

          // Wake Word Section
          _buildSectionHeader('Wake Word Detection'),
          const SizedBox(height: 12),

          _buildWakeWordToggle(),
          const SizedBox(height: 12),

          _buildPrivacyInfo(),
          const SizedBox(height: 32),

          // Background Wake Word Section
          _buildSectionHeader('Background Listening'),
          const SizedBox(height: 12),

          _buildBackgroundWakeWordToggle(),
          const SizedBox(height: 12),

          _buildBackgroundInfo(),
          const SizedBox(height: 32),

          // Voice Settings Section
          _buildSectionHeader('Voice Settings'),
          const SizedBox(height: 12),

          _buildSettingsTile(
            icon: Icons.volume_up,
            title: 'Voice Volume',
            subtitle: 'Adjust assistant voice volume',
            trailing: const Icon(Icons.chevron_right, color: Colors.white30),
            onTap: () {
              _showVolumeDialog();
            },
          ),

          _buildSettingsTile(
            icon: Icons.speed,
            title: 'Speech Rate',
            subtitle: 'Adjust how fast J.A.R.V.I.S speaks',
            trailing: const Icon(Icons.chevron_right, color: Colors.white30),
            onTap: () {
              _showSpeechRateDialog();
            },
          ),

          const SizedBox(height: 32),

          // Permissions Section
          _buildSectionHeader('Permissions'),
          const SizedBox(height: 12),

          _buildPermissionToggle(
            icon: Icons.language,
            title: 'Web/Internet',
            subtitle: 'Allow web search and online data',
            value: _webInternetEnabled,
            onChanged: (value) async {
              setState(() {
                _webInternetEnabled = value;
              });
              await SettingsManager.setPermission('web_internet', value);
            },
          ),

          _buildPermissionToggle(
            icon: Icons.folder,
            title: 'Files/Media',
            subtitle: 'Allow file and image analysis',
            value: _filesMediaEnabled,
            onChanged: (value) async {
              setState(() {
                _filesMediaEnabled = value;
              });
              await SettingsManager.setPermission('files_media', value);
            },
          ),

          _buildPermissionToggle(
            icon: Icons.message,
            title: 'Messages',
            subtitle: 'Allow message access',
            value: _messagesEnabled,
            onChanged: (value) async {
              setState(() {
                _messagesEnabled = value;
              });
              await SettingsManager.setPermission('messages', value);
            },
          ),

          _buildPermissionToggle(
            icon: Icons.contacts,
            title: 'Contacts',
            subtitle: 'Allow contact access',
            value: _contactsEnabled,
            onChanged: (value) async {
              setState(() {
                _contactsEnabled = value;
              });
              await SettingsManager.setPermission('contacts', value);
            },
          ),

          _buildPermissionToggle(
            icon: Icons.sensors,
            title: 'Sensors',
            subtitle: 'Allow sensor data access',
            value: _sensorsEnabled,
            onChanged: (value) async {
              setState(() {
                _sensorsEnabled = value;
              });
              await SettingsManager.setPermission('sensors', value);
            },
          ),

          const SizedBox(height: 32),

          // About Section
          _buildSectionHeader('About'),
          const SizedBox(height: 12),

          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF00A8E8).withValues(alpha: 0.7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildWakeWordToggle() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E2749),
            Color(0xFF2A3254),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _wakeWordEnabled
              ? const Color(0xFF00A8E8).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _wakeWordEnabled = !_wakeWordEnabled;
            });
            widget.onWakeWordToggle(_wakeWordEnabled);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00A8E8).withValues(alpha: 0.3),
                        const Color(0xFF00A8E8).withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    _wakeWordEnabled ? Icons.mic : Icons.mic_off,
                    color: _wakeWordEnabled
                        ? const Color(0xFF00A8E8)
                        : Colors.white30,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Always-On "JARVIS" Wake Word',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _wakeWordEnabled
                            ? 'Say "JARVIS" to activate'
                            : 'Tap mic button to activate',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: _wakeWordEnabled,
                  onChanged: (value) {
                    setState(() {
                      _wakeWordEnabled = value;
                    });
                    widget.onWakeWordToggle(value);
                  },
                  activeThumbColor: const Color(0xFF00A8E8),
                  activeTrackColor:
                      const Color(0xFF00A8E8).withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00A8E8).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00A8E8).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.security,
            color: const Color(0xFF00A8E8).withValues(alpha: 0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy & Security',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00A8E8).withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Audio processed locally; no cloud streaming. All voice recognition happens on your device.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundWakeWordToggle() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E2749),
            Color(0xFF2A3254),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _backgroundWakeWordEnabled
              ? const Color(0xFF00FF88).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggleBackgroundWakeWord(!_backgroundWakeWordEnabled),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00FF88).withValues(alpha: 0.3),
                        const Color(0xFF00FF88).withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: _isLoadingBackgroundService
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _backgroundWakeWordEnabled
                              ? Icons.hearing
                              : Icons.hearing_disabled,
                          color: _backgroundWakeWordEnabled
                              ? const Color(0xFF00FF88)
                              : Colors.white30,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Background Wake Word',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _backgroundWakeWordEnabled
                            ? 'Listening even when app is closed'
                            : 'Works like Siri/Google Assistant',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: _backgroundWakeWordEnabled,
                  onChanged: _isLoadingBackgroundService
                      ? null
                      : (value) => _toggleBackgroundWakeWord(value),
                  activeThumbColor: const Color(0xFF00FF88),
                  activeTrackColor:
                      const Color(0xFF00FF88).withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8800).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF8800).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.battery_alert,
            color: const Color(0xFFFF8800).withValues(alpha: 0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Battery Usage',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF8800).withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Background listening uses more battery. Requires Picovoice access key (free at console.picovoice.ai).',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E2749),
            Color(0xFF2A3254),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF00A8E8).withValues(alpha: 0.7),
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E2749),
            Color(0xFF2A3254),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? const Color(0xFF00A8E8).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: value ? const Color(0xFF00A8E8) : Colors.white30,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFF00A8E8),
              activeTrackColor: const Color(0xFF00A8E8).withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  void _showVolumeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2749),
          title: const Text(
            'Voice Volume',
            style: TextStyle(color: Colors.white),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Adjust the volume of J.A.R.V.I.S voice',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 20),
              // Placeholder for volume slider
              // This would typically connect to TTS volume settings
              Text(
                'Volume control will be integrated with TTS service',
                style: TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF00A8E8)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSpeechRateDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2749),
          title: const Text(
            'Speech Rate',
            style: TextStyle(color: Colors.white),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Adjust how fast J.A.R.V.I.S speaks',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 20),
              // Placeholder for speech rate slider
              // This would typically connect to TTS speech rate settings
              Text(
                'Speech rate control will be integrated with TTS service',
                style: TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF00A8E8)),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Settings Manager for persisting settings
class SettingsManager {
  static const String _wakeWordKey = 'wake_word_enabled';

  static Future<bool> getWakeWordEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wakeWordKey) ?? true; // Default: enabled
  }

  static Future<void> setWakeWordEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wakeWordKey, enabled);
  }

  static Future<bool> getPermission(String permission) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'permission_$permission';
    return prefs.getBool(key) ?? true; // Default: enabled
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
