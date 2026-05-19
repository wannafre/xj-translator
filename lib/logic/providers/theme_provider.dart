import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = const Color(
    0xFF7C3AED,
  ); // Default vibrant violet/purple from screenshot

  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  // Pre-configured elegant theme palettes (Private static list to avoid Web transpiler static issues)
  static const List<Map<String, dynamic>> _themePalettes = [
    {'name': '灵动紫', 'color': Color(0xFF7C3AED)},
    {'name': '晴空蓝', 'color': Color(0xFF0284C7)},
    {'name': '翡翠绿', 'color': Color(0xFF059669)},
    {'name': '胭脂红', 'color': Color(0xFFDC2626)},
    {'name': '琥珀橙', 'color': Color(0xFFD97706)},
  ];

  // Instance getter ensuring safe runtime resolution in Flutter Web
  List<Map<String, dynamic>> get themePalettes => _themePalettes;

  ThemeProvider() {
    _loadSettings();
  }

  // Load theme settings from LocalStorage
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Dark Mode status
    final int? modeIndex = prefs.getInt('theme_mode');
    if (modeIndex != null) {
      _themeMode = ThemeMode.values[modeIndex];
    }

    // Load Theme Color
    final int? colorValue = prefs.getInt('theme_color');
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }

    notifyListeners();
  }

  // Update Theme Mode (Light / Dark / System)
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  // Update primary theme color
  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_color', color.toARGB32());
  }

  // Quick toggle dark mode
  Future<void> toggleDarkMode() async {
    if (isDarkMode) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
