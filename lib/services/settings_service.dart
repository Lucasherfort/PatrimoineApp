import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const _keyShowAdvantages = 'show_advantages';

  Future<bool> getShowAdvantages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowAdvantages) ?? true;
  }

  Future<void> setShowAdvantages(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowAdvantages, value);
  }
}
