import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_service.dart';

class ThemeManager with ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  final SettingsService _settingsService = SettingsService();
  AppThemeMode _themeMode = AppThemeMode.adaptive;
  Locale? _locale;
  String _fontName = 'Default';
  final bool _displayNetWealth = false; // 👈 Toujours brut par défaut

  AppThemeMode get appThemeMode => _themeMode;
  ThemeMode get themeMode => _settingsService.mapToThemeMode(_themeMode);
  Locale? get locale => _locale;
  String get fontName => _fontName;
  bool get displayNetWealth => _displayNetWealth;

  Future<void> init() async {
    _themeMode = await _settingsService.getThemeMode();
    final langCode = await _settingsService.getLanguageCode();
    if (langCode != null) {
      _locale = Locale(langCode);
    }
    _fontName = await _settingsService.getAppFont();
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

  Future<void> setFont(String fontName) async {
    _fontName = fontName;
    await _settingsService.setAppFont(fontName);
    notifyListeners();
  }

  TextTheme getTextTheme([TextTheme? base]) {
    switch (_fontName) {
      case 'Inter':
        return GoogleFonts.interTextTheme(base);
      case 'Montserrat':
        return GoogleFonts.montserratTextTheme(base);
      case 'Plus Jakarta Sans':
        return GoogleFonts.plusJakartaSansTextTheme(base);
      default:
        return base ?? ThemeData.light().textTheme;
    }
  }
}
