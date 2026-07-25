import 'package:flutter/material.dart';
import 'settings_service.dart';

class FinancialProfileManager with ChangeNotifier {
  static final FinancialProfileManager _instance =
      FinancialProfileManager._internal();
  factory FinancialProfileManager() => _instance;
  FinancialProfileManager._internal();

  final SettingsService _settingsService = SettingsService();

  double _monthlyNetSalary = 0.0;
  double _monthlyInvestment = 0.0;

  double get monthlyNetSalary => _monthlyNetSalary;
  double get monthlyInvestment => _monthlyInvestment;

  Future<void> init() async {
    _monthlyNetSalary = await _settingsService.getMonthlyNetSalary() ?? 0.0;
    _monthlyInvestment = await _settingsService.getMonthlyInvestment() ?? 0.0;
    notifyListeners();
  }

  Future<void> setMonthlyNetSalary(double value) async {
    if (_monthlyNetSalary == value) return;
    _monthlyNetSalary = value;
    await _settingsService.setMonthlyNetSalary(value);
    notifyListeners();
  }

  Future<void> setMonthlyInvestment(double value) async {
    if (_monthlyInvestment == value) return;
    _monthlyInvestment = value;
    await _settingsService.setMonthlyInvestment(value);
    notifyListeners();
  }
}
