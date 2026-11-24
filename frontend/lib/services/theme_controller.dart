import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const String preferenceKey = 'cinebook.themeMode';

  final SharedPreferences? _preferences;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _loaded = false;
  bool _disposed = false;

  ThemeController({SharedPreferences? preferences}) : _preferences = preferences;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    if (_loaded) return;
    final preferences = await _getPreferences();
    final saved = preferences.getString(preferenceKey);
    _themeMode = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.dark,
    };
    _loaded = true;
    _notify();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _notify();
    final preferences = await _getPreferences();
    await preferences.setString(preferenceKey, mode.name);
  }

  Future<void> toggle() {
    return setThemeMode(
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  Future<SharedPreferences> _getPreferences() async {
    return _preferences ?? await SharedPreferences.getInstance();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
