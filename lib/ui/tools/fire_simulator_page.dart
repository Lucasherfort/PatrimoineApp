import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/patrimoine_service.dart';
import '../../services/financial_profile_manager.dart';

class FireSimulatorPage extends StatefulWidget {
  const FireSimulatorPage({super.key});

  @override
  State<FireSimulatorPage> createState() => _FireSimulatorPageState();
}

class _FireSimulatorPageState extends State<FireSimulatorPage> {
  final _savingsController = TextEditingController();
  final _dcaController = TextEditingController();
  final _expensesController = TextEditingController();
  final _ageController = TextEditingController();

  double _annualReturn = 7.0;
  double _swr = 4.0;
  bool _isLoading = true;

  final _formatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final netWealth = await PatrimoineService().getNetPatrimoine();
      final profile = FinancialProfileManager();

      if (mounted) {
        setState(() {
          _savingsController.text = netWealth.toStringAsFixed(0);
          _dcaController.text = profile.monthlyInvestment.toStringAsFixed(0);
          _expensesController.text = profile.monthlyNetSalary.toStringAsFixed(
            0,
          );
          _ageController.text = profile.currentAge.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _savingsController.dispose();
    _dcaController.dispose();
    _expensesController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // --- CALCULS ---

  double get _currentSavings => double.tryParse(_savingsController.text) ?? 0;
  double get _monthlyDca => double.tryParse(_dcaController.text) ?? 0;
  double get _monthlyExpenses => double.tryParse(_expensesController.text) ?? 0;
  int get _currentAge => int.tryParse(_ageController.text) ?? 30;

  double get _fireNumber {
    if (_swr <= 0) return 0;
    return (_monthlyExpenses * 12) / (_swr / 100);
  }

  Map<String, dynamic> _calculateFireAge() {
    double currentBalance = _currentSavings;
    final monthlyRate = (_annualReturn / 100) / 12;
    int months = 0;
    const int maxMonths = 600; // 50 years cap

    while (currentBalance < _fireNumber && months < maxMonths) {
      currentBalance = (currentBalance + _monthlyDca) * (1 + monthlyRate);
      months++;
    }

    return {
      'age': _currentAge + (months / 12),
      'months': months,
      'finalBalance': currentBalance,
    };
  }

  @override
  Widget build(BuildContext context) {
    const Color colorBlue = Color(0xFF0D71EE);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: colorBlue)),
      );
    }

    final fireResult = _calculateFireAge();
    final double fireAge = fireResult['age'];
    final bool isFirePossible = fireResult['months'] < 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        title: Text(
          "Retraite & FIRE",
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: theme.iconTheme.color),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- RESULT CARD ---
            _buildFireResultCard(context, fireAge, isFirePossible),

            const SizedBox(height: 32),

            // --- KPIs ---
            _buildSectionTitle(context, "INDICATEURS CLÉS"),
            Row(
              children: [
                Expanded(
                  child: _buildSmallKPI(
                    context,
                    "Montant cible",
                    _formatter.format(_fireNumber),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSmallKPI(
                    context,
                    "Gains / mois",
                    _formatter.format(_fireNumber * (_swr / 100) / 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // --- INPUTS ---
            _buildSectionTitle(context, "VOTRE SITUATION"),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    context,
                    label: "Âge actuel",
                    controller: _ageController,
                    icon: Icons.person,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    context,
                    label: "Épargne (€)",
                    controller: _savingsController,
                    icon: Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInputField(
              context,
              label: "Versement mensuel (€)",
              controller: _dcaController,
              icon: Icons.add_chart,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              context,
              label: "Dépenses cibles / mois (€)",
              controller: _expensesController,
              icon: Icons.shopping_bag_outlined,
            ),

            const SizedBox(height: 32),

            _buildSectionTitle(context, "HYPOTHÈSES"),
            _buildSliderLabel(
              context,
              "Rendement annuel",
              "${_annualReturn.toStringAsFixed(1)}%",
            ),
            Slider(
              value: _annualReturn,
              min: 1,
              max: 15,
              divisions: 140,
              activeColor: colorBlue,
              onChanged: (val) => setState(() => _annualReturn = val),
            ),
            _buildSliderLabel(
              context,
              "Taux de retrait (SWR)",
              "${_swr.toStringAsFixed(1)}%",
            ),
            Slider(
              value: _swr,
              min: 2,
              max: 8,
              divisions: 60,
              activeColor: colorBlue,
              onChanged: (val) => setState(() => _swr = val),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFireResultCard(BuildContext context, double age, bool possible) {
    final colorBlue = const Color(0xFF0D71EE);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorBlue, colorBlue.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Indépendance financière",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            possible
                ? "Vous serez FIRE à ${age.toStringAsFixed(1)} ans"
                : "Objectif hors de portée",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              possible
                  ? "Dans ${(age - _currentAge).toStringAsFixed(1)} ans"
                  : "Ajustez vos paramètres",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallKPI(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? null
            : Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black45,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? null
            : Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.white30 : Colors.black26,
            fontSize: 12,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF0D71EE), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSliderLabel(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0D71EE),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
