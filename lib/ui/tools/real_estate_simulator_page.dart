import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/patrimoine_service.dart';
import '../../services/financial_profile_manager.dart';

class RealEstateSimulatorPage extends StatefulWidget {
  const RealEstateSimulatorPage({super.key});

  @override
  State<RealEstateSimulatorPage> createState() =>
      _RealEstateSimulatorPageState();
}

class _RealEstateSimulatorPageState extends State<RealEstateSimulatorPage> {
  final _salaryController = TextEditingController(text: "2500");
  final _downPaymentController = TextEditingController(text: "0");

  double _loanDurationYears = 20;
  double _interestRate = 3.8;
  final double _insuranceRate = 0.34;
  double _netPatrimoine = 0;
  bool _isLoading = true;

  final _formatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadPatrimoine();
  }

  Future<void> _loadPatrimoine() async {
    try {
      final value = await PatrimoineService().getNetPatrimoine();
      final financialProfile = FinancialProfileManager();

      if (mounted) {
        setState(() {
          _netPatrimoine = value;
          // On suggère par défaut d'utiliser 80% du patrimoine net (sécurité)
          _downPaymentController.text = (_netPatrimoine * 0.8).toStringAsFixed(
            0,
          );

          // Report du salaire depuis le profil financier si renseigné
          if (financialProfile.monthlyNetSalary > 0) {
            _salaryController.text = financialProfile.monthlyNetSalary
                .toStringAsFixed(0);
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _downPaymentController.dispose();
    super.dispose();
  }

  // --- CALCULS ---

  double get _monthlySalary => double.tryParse(_salaryController.text) ?? 0;
  double get _downPayment => double.tryParse(_downPaymentController.text) ?? 0;

  /// Capacité de remboursement mensuelle (35% d'endettement max)
  double get _maxMonthlyPayment => _monthlySalary * 0.35;

  /// Capacité d'emprunt totale
  double get _borrowingCapacity {
    if (_maxMonthlyPayment <= 0) return 0;

    // Taux mensuel (intérêts + assurance)
    double monthlyRate = (_interestRate + _insuranceRate) / 100 / 12;
    double numMonths = _loanDurationYears * 12;

    if (monthlyRate == 0) return _maxMonthlyPayment * numMonths;

    // Formule : P = M * [(1+r)^n - 1] / [r * (1+r)^n]
    return _maxMonthlyPayment *
        (pow(1 + monthlyRate, numMonths) - 1) /
        (monthlyRate * pow(1 + monthlyRate, numMonths));
  }

  /// Valeur maximale du bien (en incluant les frais de notaire à 7.5% environ)
  /// Prix du bien + 7.5% de frais de notaire = Capacité d'emprunt + Apport
  /// Prix du bien = (Capacité + Apport) / 1.075
  double get _maxPropertyPrice {
    return (_borrowingCapacity + _downPayment) / 1.075;
  }

  /// Apport max conseillé : 80% du patrimoine net disponible (pour garder une poche de sécurité)
  double get _recommendedMaxDownPayment {
    return _netPatrimoine * 0.8;
  }

  @override
  Widget build(BuildContext context) {
    const Color colorBlue = Color(0xFF0D71EE);
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: colorBlue)),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        title: Text(
          "Simulateur Immobilier",
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
            // --- ENTRÉES ---
            _buildSectionTitle(context, "VOS DONNÉES"),
            _buildInputField(
              context,
              label: "Salaire net mensuel (€)",
              controller: _salaryController,
              icon: Icons.payments,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildInputField(
                    context,
                    label: "Apport personnel (€)",
                    controller: _downPaymentController,
                    icon: Icons.savings,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildSmallResultCard(
                    context,
                    title: "Conseillé (80%)",
                    value: _formatter.format(_recommendedMaxDownPayment),
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(context, "PARAMÈTRES DU CRÉDIT"),
            _buildSliderLabel(
              context,
              "Durée du prêt",
              "${_loanDurationYears.toInt()} ans",
            ),
            Slider(
              value: _loanDurationYears,
              min: 5,
              max: 30,
              divisions: 5,
              activeColor: colorBlue,
              onChanged: (val) => setState(() => _loanDurationYears = val),
            ),

            _buildSliderLabel(
              context,
              "Taux d'intérêt",
              "${_interestRate.toStringAsFixed(2)}%",
            ),
            Slider(
              value: _interestRate,
              min: 0.5,
              max: 6.0,
              divisions: 55,
              activeColor: colorBlue,
              onChanged: (val) => setState(() => _interestRate = val),
            ),

            const SizedBox(height: 32),

            // --- RÉSULTATS ---
            _buildSectionTitle(context, "RÉSULTATS DE LA SIMULATION"),

            _buildResultCard(
              context,
              title: "Capacité d'achat maximale",
              value: _formatter.format(_maxPropertyPrice),
              subtitle: "Frais de notaire (7.5%) inclus",
              isPrimary: true,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildSmallResultCard(
                    context,
                    title: "Mensualité max (35%)",
                    value: "${_maxMonthlyPayment.toInt()} €",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSmallResultCard(
                    context,
                    title: "Capacité d'emprunt",
                    value: _formatter.format(_borrowingCapacity),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black45,
          fontSize: 12,
          fontWeight: FontWeight.bold,
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
            : Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        style: TextStyle(
          color: theme.textTheme.bodyLarge?.color,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.white60 : Colors.black45,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF0D71EE)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
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
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0D71EE),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    bool isPrimary = false,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF0D71EE) : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: !isPrimary && !isDark
            ? Border.all(color: Colors.black.withValues(alpha: 0.05))
            : null,
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: const Color(0xFF0D71EE).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isPrimary
                  ? Colors.white70
                  : (isDark ? Colors.white60 : Colors.black54),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color:
                  color ??
                  (isPrimary
                      ? Colors.white
                      : theme.textTheme.titleLarge?.color),
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: isPrimary
                  ? Colors.white60
                  : (isDark ? Colors.white38 : Colors.black38),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallResultCard(
    BuildContext context, {
    required String title,
    required String value,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? null
            : Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black45,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color ?? theme.textTheme.bodyLarge?.color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
