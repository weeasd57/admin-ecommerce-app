import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  ThemeProvider() {
    _loadThemePreferences();
  }

  bool get isDarkMode => _isDarkMode;

  ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        // Remove color-specific settings
      );

  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}
