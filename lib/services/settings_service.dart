import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, adaptive }

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const _keyThemeMode = 'theme_mode';
  static const _keyMonthlyNetSalary = 'monthly_net_salary';
  static const _keyMonthlyInvestment = 'monthly_investment';
  static const _keyRetirementDesiredIncome = 'retirement_desired_income';
  static const _keyRetirementEstimatedPension = 'retirement_estimated_pension';
  static const _keyRetirementSwr = 'retirement_swr';

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

  Future<double?> getMonthlyNetSalary() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyMonthlyNetSalary);
  }

  Future<void> setMonthlyNetSalary(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMonthlyNetSalary, value);
  }

  Future<double?> getMonthlyInvestment() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyMonthlyInvestment);
  }

  Future<void> setMonthlyInvestment(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMonthlyInvestment, value);
  }

  // --- Retraite ---

  Future<double?> getRetirementDesiredIncome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyRetirementDesiredIncome);
  }

  Future<void> setRetirementDesiredIncome(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyRetirementDesiredIncome, value);
  }

  Future<double?> getRetirementEstimatedPension() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyRetirementEstimatedPension);
  }

  Future<void> setRetirementEstimatedPension(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyRetirementEstimatedPension, value);
  }

  Future<double> getRetirementSwr() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyRetirementSwr) ?? 4.0;
  }

  Future<void> setRetirementSwr(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyRetirementSwr, value);
  }

  Future<double> getInflationRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyInflationRate) ?? 2.0;
  }

  Future<void> setInflationRate(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyInflationRate, value);
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
