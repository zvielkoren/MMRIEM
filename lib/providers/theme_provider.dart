import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;
  final SharedPreferences _prefs;

  ThemeProvider(this._prefs) {
    _loadTheme();
  }

  bool get isDark => _isDark;

  void _loadTheme() {
    _isDark = _prefs.getBool('isDark') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    await _prefs.setBool('isDark', _isDark);
    notifyListeners();
  }
}
