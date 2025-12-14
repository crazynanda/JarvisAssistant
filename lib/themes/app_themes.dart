import 'package:flutter/material.dart';

/// Available app themes
enum AppThemeType {
  ironMan,
  cyberpunk,
  minimalDark,
  glassmorphism,
  hal9000,
  terminal,
}

/// Theme configuration with all properties
class AppThemeConfig {
  final String name;
  final String description;
  final IconData icon;

  // Colors
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color secondaryTextColor;

  // Orb colors
  final Color orbPrimaryColor;
  final Color orbSecondaryColor;
  final Color orbGlowColor;

  // Message colors
  final Color userBubbleColor;
  final Color assistantBubbleColor;
  final Color userTextColor;
  final Color assistantTextColor;

  // Header
  final Color headerColor;
  final Color headerTextColor;

  // Input bar
  final Color inputBarColor;
  final Color inputTextColor;
  final Color inputHintColor;

  // Special properties
  final String? fontFamily; // null = default, 'monospace' for terminal
  final bool useGlowEffects;
  final bool useBlurEffects;
  final bool useTypingAnimation; // For terminal theme
  final double borderRadius;

  // Gradient for background
  final List<Color> backgroundGradient;

  const AppThemeConfig({
    required this.name,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.orbPrimaryColor,
    required this.orbSecondaryColor,
    required this.orbGlowColor,
    required this.userBubbleColor,
    required this.assistantBubbleColor,
    required this.userTextColor,
    required this.assistantTextColor,
    required this.headerColor,
    required this.headerTextColor,
    required this.inputBarColor,
    required this.inputTextColor,
    required this.inputHintColor,
    this.fontFamily,
    this.useGlowEffects = true,
    this.useBlurEffects = false,
    this.useTypingAnimation = false,
    this.borderRadius = 24.0,
    required this.backgroundGradient,
  });
}

/// All available themes
class AppThemes {
  // 1. Iron Man JARVIS Theme
  static const ironMan = AppThemeConfig(
    name: 'Iron Man JARVIS',
    description: 'Holographic HUD with orange & cyan',
    icon: Icons.memory,
    primaryColor: Color(0xFFFF6B35),
    accentColor: Color(0xFF00D4FF),
    backgroundColor: Color(0xFF0A0E17),
    surfaceColor: Color(0xFF1A1F2E),
    textColor: Color(0xFFFFFFFF),
    secondaryTextColor: Color(0xFF8B9DC3),
    orbPrimaryColor: Color(0xFFFF6B35),
    orbSecondaryColor: Color(0xFF00D4FF),
    orbGlowColor: Color(0xFFFF6B35),
    userBubbleColor: Color(0xFF00D4FF),
    assistantBubbleColor: Color(0xFF1A1F2E),
    userTextColor: Color(0xFF0A0E17),
    assistantTextColor: Color(0xFFFFFFFF),
    headerColor: Color(0xFF1A1F2E),
    headerTextColor: Color(0xFFFF6B35),
    inputBarColor: Color(0xFF1A1F2E),
    inputTextColor: Color(0xFFFFFFFF),
    inputHintColor: Color(0xFF8B9DC3),
    useGlowEffects: true,
    useBlurEffects: true,
    backgroundGradient: [
      Color(0xFF0A0E17),
      Color(0xFF1A1F2E),
      Color(0xFF0A0E17)
    ],
  );

  // 2. Cyberpunk Theme
  static const cyberpunk = AppThemeConfig(
    name: 'Cyberpunk',
    description: 'Neon purple & pink glow effects',
    icon: Icons.electric_bolt,
    primaryColor: Color(0xFF9D4EDD),
    accentColor: Color(0xFFFF006E),
    backgroundColor: Color(0xFF10002B),
    surfaceColor: Color(0xFF240046),
    textColor: Color(0xFFFFFFFF),
    secondaryTextColor: Color(0xFFE0AAFF),
    orbPrimaryColor: Color(0xFFFF006E),
    orbSecondaryColor: Color(0xFF9D4EDD),
    orbGlowColor: Color(0xFFFF006E),
    userBubbleColor: Color(0xFFFF006E),
    assistantBubbleColor: Color(0xFF240046),
    userTextColor: Color(0xFFFFFFFF),
    assistantTextColor: Color(0xFFE0AAFF),
    headerColor: Color(0xFF240046),
    headerTextColor: Color(0xFFFF006E),
    inputBarColor: Color(0xFF240046),
    inputTextColor: Color(0xFFFFFFFF),
    inputHintColor: Color(0xFFE0AAFF),
    useGlowEffects: true,
    useBlurEffects: true,
    backgroundGradient: [
      Color(0xFF10002B),
      Color(0xFF240046),
      Color(0xFF3C096C)
    ],
  );

  // 3. Minimal Dark Theme
  static const minimalDark = AppThemeConfig(
    name: 'Minimal Dark',
    description: 'Clean and simple dark mode',
    icon: Icons.dark_mode,
    primaryColor: Color(0xFFFFFFFF),
    accentColor: Color(0xFF888888),
    backgroundColor: Color(0xFF000000),
    surfaceColor: Color(0xFF1A1A1A),
    textColor: Color(0xFFFFFFFF),
    secondaryTextColor: Color(0xFF888888),
    orbPrimaryColor: Color(0xFF444444),
    orbSecondaryColor: Color(0xFF666666),
    orbGlowColor: Color(0xFF333333),
    userBubbleColor: Color(0xFF333333),
    assistantBubbleColor: Color(0xFF1A1A1A),
    userTextColor: Color(0xFFFFFFFF),
    assistantTextColor: Color(0xFFCCCCCC),
    headerColor: Color(0xFF1A1A1A),
    headerTextColor: Color(0xFFFFFFFF),
    inputBarColor: Color(0xFF1A1A1A),
    inputTextColor: Color(0xFFFFFFFF),
    inputHintColor: Color(0xFF666666),
    useGlowEffects: false,
    useBlurEffects: false,
    borderRadius: 12.0,
    backgroundGradient: [
      Color(0xFF000000),
      Color(0xFF0A0A0A),
      Color(0xFF000000)
    ],
  );

  // 4. Glassmorphism Theme
  static const glassmorphism = AppThemeConfig(
    name: 'Glassmorphism',
    description: 'Frosted glass with blur effects',
    icon: Icons.blur_on,
    primaryColor: Color(0xFF00A8E8),
    accentColor: Color(0xFF00F0FF),
    backgroundColor: Color(0xFF050A18),
    surfaceColor: Color(0xFF0F1C3F),
    textColor: Color(0xFFFFFFFF),
    secondaryTextColor: Color(0xFF8B9DC3),
    orbPrimaryColor: Color(0xFF00F0FF),
    orbSecondaryColor: Color(0xFF00A8E8),
    orbGlowColor: Color(0xFF00F0FF),
    userBubbleColor: Color(0xFF4D9FFF),
    assistantBubbleColor: Color(0xFF1E2749),
    userTextColor: Color(0xFFFFFFFF),
    assistantTextColor: Color(0xFFFFFFFF),
    headerColor: Color(0xFF1E2749),
    headerTextColor: Color(0xFF00F0FF),
    inputBarColor: Color(0xFF1E2749),
    inputTextColor: Color(0xFFFFFFFF),
    inputHintColor: Color(0xFF8B9DC3),
    useGlowEffects: true,
    useBlurEffects: true,
    backgroundGradient: [Color(0xFF0F1C3F), Color(0xFF050A18)],
  );

  // 5. HAL 9000 Theme
  static const hal9000 = AppThemeConfig(
    name: 'HAL 9000',
    description: 'Sci-fi minimal with red accent',
    icon: Icons.remove_red_eye,
    primaryColor: Color(0xFFFF0000),
    accentColor: Color(0xFFFF3333),
    backgroundColor: Color(0xFF000000),
    surfaceColor: Color(0xFF0D0D0D),
    textColor: Color(0xFFFFFFFF),
    secondaryTextColor: Color(0xFF999999),
    orbPrimaryColor: Color(0xFFFF0000),
    orbSecondaryColor: Color(0xFF330000),
    orbGlowColor: Color(0xFFFF0000),
    userBubbleColor: Color(0xFF330000),
    assistantBubbleColor: Color(0xFF0D0D0D),
    userTextColor: Color(0xFFFF3333),
    assistantTextColor: Color(0xFFFFFFFF),
    headerColor: Color(0xFF0D0D0D),
    headerTextColor: Color(0xFFFF0000),
    inputBarColor: Color(0xFF0D0D0D),
    inputTextColor: Color(0xFFFFFFFF),
    inputHintColor: Color(0xFF666666),
    useGlowEffects: true,
    useBlurEffects: false,
    borderRadius: 4.0,
    backgroundGradient: [
      Color(0xFF000000),
      Color(0xFF0D0D0D),
      Color(0xFF000000)
    ],
  );

  // 6. Terminal Theme
  static const terminal = AppThemeConfig(
    name: 'Terminal',
    description: 'Classic command line interface',
    icon: Icons.terminal,
    primaryColor: Color(0xFF00FF00),
    accentColor: Color(0xFF00CC00),
    backgroundColor: Color(0xFF0C0C0C),
    surfaceColor: Color(0xFF1A1A1A),
    textColor: Color(0xFF00FF00),
    secondaryTextColor: Color(0xFF00AA00),
    orbPrimaryColor: Color(0xFF00FF00),
    orbSecondaryColor: Color(0xFF004400),
    orbGlowColor: Color(0xFF00FF00),
    userBubbleColor: Color(0xFF0C0C0C),
    assistantBubbleColor: Color(0xFF0C0C0C),
    userTextColor: Color(0xFF00FF00),
    assistantTextColor: Color(0xFF00FF00),
    headerColor: Color(0xFF0C0C0C),
    headerTextColor: Color(0xFF00FF00),
    inputBarColor: Color(0xFF0C0C0C),
    inputTextColor: Color(0xFF00FF00),
    inputHintColor: Color(0xFF006600),
    fontFamily: 'monospace',
    useGlowEffects: false,
    useBlurEffects: false,
    useTypingAnimation: true,
    borderRadius: 0.0,
    backgroundGradient: [Color(0xFF0C0C0C), Color(0xFF0C0C0C)],
  );

  /// Get theme by type
  static AppThemeConfig getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.ironMan:
        return ironMan;
      case AppThemeType.cyberpunk:
        return cyberpunk;
      case AppThemeType.minimalDark:
        return minimalDark;
      case AppThemeType.glassmorphism:
        return glassmorphism;
      case AppThemeType.hal9000:
        return hal9000;
      case AppThemeType.terminal:
        return terminal;
    }
  }

  /// All themes list
  static List<AppThemeType> get allThemes => AppThemeType.values;
}
