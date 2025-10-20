import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeProvider() {
    _loadTheme(); 
  }

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
    print("Theme changed: $_isDark");
    _saveTheme();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDark);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDarkMode') ?? false; 
    print("Theme loaded: $_isDark");
    notifyListeners();
  }
}
