import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  AppThemeType _themeType = AppThemeType.softLatte;

  AppThemeType get themeType => _themeType;
  ThemeData get themeData => AppTheme.getTheme(_themeType);

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey);
    if (themeName != null) {
      try {
        _themeType = AppThemeType.values.firstWhere((e) => e.name == themeName);
        notifyListeners();
      } catch (e) {
        // Ignore if theme name is invalid
      }
    }
  }

  Future<void> setTheme(AppThemeType type) async {
    _themeType = type;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, type.name);
  }
}
