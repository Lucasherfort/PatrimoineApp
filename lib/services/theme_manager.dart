import 'package:flutter/material.dart';
import 'settings_service.dart';

class ThemeManager with ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  final SettingsService _settingsService = SettingsService();
  AppThemeMode _themeMode = AppThemeMode.adaptive;
  Locale? _locale;
  final bool _displayNetWealth = false; // 👈 Toujours brut par défaut

  AppThemeMode get appThemeMode => _themeMode;
  ThemeMode get themeMode => _settingsService.mapToThemeMode(_themeMode);
  Locale? get locale => _locale;
  bool get displayNetWealth => _displayNetWealth;

  Future<void> init() async {
    _themeMode = await _settingsService.getThemeMode();
    final langCode = await _settingsService.getLanguageCode();
    if (langCode != null) {
      _locale = Locale(langCode);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _settingsService.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setLocale(String? langCode) async {
    if (langCode == null) {
      _locale = null;
    } else {
      _locale = Locale(langCode);
    }
    await _settingsService.setLanguageCode(langCode);
    notifyListeners();
  }
}
