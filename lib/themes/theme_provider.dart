import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_themes.dart';

/// Theme provider with persistence
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';

  AppThemeType _currentThemeType = AppThemeType.ironMan; // Iron Man default
  AppThemeConfig _currentTheme = AppThemes.ironMan;

  AppThemeType get currentThemeType => _currentThemeType;
  AppThemeConfig get theme => _currentTheme;

  /// Initialize and load saved theme
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);

    if (savedTheme != null) {
      try {
        _currentThemeType = AppThemeType.values.firstWhere(
          (t) => t.name == savedTheme,
          orElse: () => AppThemeType.glassmorphism,
        );
        _currentTheme = AppThemes.getTheme(_currentThemeType);
      } catch (e) {
        // Use default if parsing fails
        _currentThemeType = AppThemeType.glassmorphism;
        _currentTheme = AppThemes.glassmorphism;
      }
    }

    notifyListeners();
  }

  /// Set new theme and persist
  Future<void> setTheme(AppThemeType themeType) async {
    _currentThemeType = themeType;
    _currentTheme = AppThemes.getTheme(themeType);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeType.name);

    notifyListeners();
  }

  /// Get all available themes
  List<AppThemeType> get availableThemes => AppThemes.allThemes;

  /// Get config for any theme
  AppThemeConfig getThemeConfig(AppThemeType type) => AppThemes.getTheme(type);
}
