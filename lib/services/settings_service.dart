import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyTargetBalance = 'target_bank_balance';

  // Sauvegarder le seuil
  Future<void> setTargetBalance(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTargetBalance, value);
  }

  // Lire le seuil (300.0 par défaut)
  Future<double> getTargetBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyTargetBalance) ?? 300.0;
  }
}