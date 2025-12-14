import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../themes/app_themes.dart';
import '../../themes/theme_provider.dart';
import 'terminal_theme_ui.dart';
import 'ironman_theme_ui.dart';
import 'hal9000_theme_ui.dart';
import 'cyberpunk_theme_ui.dart';
import 'minimal_dark_theme_ui.dart';
import 'glassmorphism_theme_ui.dart';

/// Routes to the correct theme UI based on current theme selection
/// Wraps theme UIs with a shared drawer for theme switching
class ThemedChatScreen extends StatefulWidget {
  final List<dynamic> messages;
  final bool isProcessing;
  final bool isListening;
  final TextEditingController textController;
  final VoidCallback onSend;
  final VoidCallback onMicPressed;
  final VoidCallback onNewChat;
  final VoidCallback onSettings;

  const ThemedChatScreen({
    super.key,
    required this.messages,
    required this.isProcessing,
    required this.isListening,
    required this.textController,
    required this.onSend,
    required this.onMicPressed,
    required this.onNewChat,
    required this.onSettings,
  });

  @override
  State<ThemedChatScreen> createState() => _ThemedChatScreenState();
}

class _ThemedChatScreenState extends State<ThemedChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.theme;

        return Scaffold(
          key: _scaffoldKey,
          drawer: _buildDrawer(context, themeProvider, theme),
          body: _buildThemeUI(themeProvider, theme),
        );
      },
    );
  }

  Widget _buildDrawer(
      BuildContext context, ThemeProvider themeProvider, AppThemeConfig theme) {
    return Drawer(
      backgroundColor: theme.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: theme.backgroundGradient.length >= 2
                      ? [theme.backgroundGradient[0], theme.surfaceColor]
                      : [theme.backgroundColor, theme.surfaceColor],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          theme.orbPrimaryColor,
                          theme.orbSecondaryColor
                        ],
                      ),
                      boxShadow: theme.useGlowEffects
                          ? [
                              BoxShadow(
                                  color:
                                      theme.orbGlowColor.withValues(alpha: 0.5),
                                  blurRadius: 15)
                            ]
                          : [],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'J.A.R.V.I.S.',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontFamily: theme.fontFamily,
                    ),
                  ),
                ],
              ),
            ),

            // New Chat
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: theme.accentColor),
              title: Text('New Chat',
                  style: TextStyle(
                      color: theme.textColor, fontFamily: theme.fontFamily)),
              onTap: () {
                Navigator.pop(context);
                widget.onNewChat();
              },
            ),

            const Divider(color: Colors.white24),

            // Theme Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'THEMES',
                style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 12,
                    letterSpacing: 1),
              ),
            ),

            // Theme Options
            Expanded(
              child: ListView.builder(
                itemCount: themeProvider.availableThemes.length,
                itemBuilder: (context, index) {
                  final themeType = themeProvider.availableThemes[index];
                  final themeConfig = themeProvider.getThemeConfig(themeType);
                  final isSelected =
                      themeType == themeProvider.currentThemeType;

                  return ListTile(
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            themeConfig.orbPrimaryColor,
                            themeConfig.orbSecondaryColor
                          ],
                        ),
                      ),
                    ),
                    title: Text(
                      themeConfig.name,
                      style: TextStyle(
                        color: isSelected ? theme.accentColor : theme.textColor,
                        fontFamily: theme.fontFamily,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check, color: theme.accentColor)
                        : null,
                    onTap: () {
                      themeProvider.setTheme(themeType);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),

            const Divider(color: Colors.white24),

            // Settings
            ListTile(
              leading: Icon(Icons.settings_outlined,
                  color: theme.secondaryTextColor),
              title: Text('Settings',
                  style: TextStyle(
                      color: theme.textColor, fontFamily: theme.fontFamily)),
              onTap: () {
                Navigator.pop(context);
                widget.onSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeUI(ThemeProvider themeProvider, AppThemeConfig theme) {
    switch (themeProvider.currentThemeType) {
      case AppThemeType.ironMan:
        return IronManThemeUI(
          messages: widget.messages,
          isProcessing: widget.isProcessing,
          isListening: widget.isListening,
          textController: widget.textController,
          onSend: widget.onSend,
          onMicPressed: widget.onMicPressed,
          onMenuPressed: _openDrawer,
          onSettingsPressed: widget.onSettings,
          theme: theme,
        );

      case AppThemeType.cyberpunk:
        return CyberpunkThemeUI(
          messages: widget.messages,
          isProcessing: widget.isProcessing,
          isListening: widget.isListening,
          textController: widget.textController,
          onSend: widget.onSend,
          onMicPressed: widget.onMicPressed,
          onMenuPressed: _openDrawer,
          onSettingsPressed: widget.onSettings,
          theme: theme,
        );

      case AppThemeType.minimalDark:
        return MinimalDarkThemeUI(
          messages: widget.messages,
          isProcessing: widget.isProcessing,
          isListening: widget.isListening,
          textController: widget.textController,
          onSend: widget.onSend,
          onMicPressed: widget.onMicPressed,
          onMenuPressed: _openDrawer,
          onSettingsPressed: widget.onSettings,
          theme: theme,
        );

      case AppThemeType.glassmorphism:
        return GlassmorphismThemeUI(
          messages: widget.messages,
          isProcessing: widget.isProcessing,
          isListening: widget.isListening,
          textController: widget.textController,
          onSend: widget.onSend,
          onMicPressed: widget.onMicPressed,
          onMenuPressed: _openDrawer,
          onSettingsPressed: widget.onSettings,
          theme: theme,
        );

      case AppThemeType.hal9000:
        return Hal9000ThemeUI(
          messages: widget.messages,
          isProcessing: widget.isProcessing,
          isListening: widget.isListening,
          textController: widget.textController,
          onSend: widget.onSend,
          onMicPressed: widget.onMicPressed,
          onMenuPressed: _openDrawer,
          onSettingsPressed: widget.onSettings,
          theme: theme,
        );

      case AppThemeType.terminal:
        return TerminalThemeUI(
          messages: widget.messages,
          isProcessing: widget.isProcessing,
          isListening: widget.isListening,
          textController: widget.textController,
          onSend: widget.onSend,
          onMicPressed: widget.onMicPressed,
          onMenuPressed: _openDrawer,
          onSettingsPressed: widget.onSettings,
          theme: theme,
        );
    }
  }
}
