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

  // Retraite
  double _retirementDesiredIncome = 0.0;
  double _retirementEstimatedPension = 0.0;
  double _retirementSwr = 4.0;

  double get monthlyNetSalary => _monthlyNetSalary;
  double get monthlyInvestment => _monthlyInvestment;
  double get retirementDesiredIncome => _retirementDesiredIncome;
  double get retirementEstimatedPension => _retirementEstimatedPension;
  double get retirementSwr => _retirementSwr;

  Future<void> init() async {
    _monthlyNetSalary = await _settingsService.getMonthlyNetSalary() ?? 0.0;
    _monthlyInvestment = await _settingsService.getMonthlyInvestment() ?? 0.0;
    _retirementDesiredIncome =
        await _settingsService.getRetirementDesiredIncome() ?? 0.0;
    _retirementEstimatedPension =
        await _settingsService.getRetirementEstimatedPension() ?? 0.0;
    _retirementSwr = await _settingsService.getRetirementSwr();
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

  Future<void> setRetirementDesiredIncome(double value) async {
    if (_retirementDesiredIncome == value) return;
    _retirementDesiredIncome = value;
    await _settingsService.setRetirementDesiredIncome(value);
    notifyListeners();
  }

  Future<void> setRetirementEstimatedPension(double value) async {
    if (_retirementEstimatedPension == value) return;
    _retirementEstimatedPension = value;
    await _settingsService.setRetirementEstimatedPension(value);
    notifyListeners();
  }

  Future<void> setRetirementSwr(double value) async {
    if (_retirementSwr == value) return;
    _retirementSwr = value;
    await _settingsService.setRetirementSwr(value);
    notifyListeners();
  }
}
