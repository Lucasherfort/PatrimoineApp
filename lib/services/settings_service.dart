import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, adaptive }

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const _keyThemeMode = 'theme_mode';
  static const _keyDisplayNetWealth = 'display_net_wealth';

  Future<AppThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyThemeMode);

    if (value == 'light') return AppThemeMode.light;
    if (value == 'dark') return AppThemeMode.dark;
    return AppThemeMode.adaptive;
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode.name);
  }

  Future<bool> getDisplayNetWealth() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDisplayNetWealth) ?? false;
  }

  Future<void> setDisplayNetWealth(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDisplayNetWealth, value);
  }

  ThemeMode mapToThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.adaptive:
        return ThemeMode.system;
    }
  }
}
