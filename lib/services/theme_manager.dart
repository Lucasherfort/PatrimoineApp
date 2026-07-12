import 'package:flutter/material.dart';
import 'settings_service.dart';

class ThemeManager with ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  final SettingsService _settingsService = SettingsService();
  AppThemeMode _themeMode = AppThemeMode.adaptive;

  AppThemeMode get appThemeMode => _themeMode;
  ThemeMode get themeMode => _settingsService.mapToThemeMode(_themeMode);

  Future<void> init() async {
    _themeMode = await _settingsService.getThemeMode();
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _settingsService.setThemeMode(mode);
    notifyListeners();
  }
}
