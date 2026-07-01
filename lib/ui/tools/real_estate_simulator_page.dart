import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/patrimoine_service.dart';

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
  double _insuranceRate = 0.34;
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
      if (mounted) {
        setState(() {
          _netPatrimoine = value;
          // On suggère par défaut d'utiliser 80% du patrimoine net (sécurité)
          _downPaymentController.text = (_netPatrimoine * 0.8).toStringAsFixed(
            0,
          );
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
    const Color colorDarkBg = Color(0xFF060B26);
    const Color colorSurface = Color(0xFF1E293B);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: colorDarkBg,
        body: Center(child: CircularProgressIndicator(color: colorBlue)),
      );
    }

    return Scaffold(
      backgroundColor: colorDarkBg,
      appBar: AppBar(
        backgroundColor: colorSurface,
        title: const Text(
          "Simulateur Immobilier",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ENTRÉES ---
            _buildSectionTitle("VOS DONNÉES"),
            _buildInputField(
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
                    label: "Apport personnel (€)",
                    controller: _downPaymentController,
                    icon: Icons.savings,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildSmallResultCard(
                    title: "Conseillé (80%)",
                    value: _formatter.format(_recommendedMaxDownPayment),
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionTitle("PARAMÈTRES DU CRÉDIT"),
            _buildSliderLabel(
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
            _buildSectionTitle("RÉSULTATS DE LA SIMULATION"),

            _buildResultCard(
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
                    title: "Mensualité max (35%)",
                    value: "${_maxMonthlyPayment.toInt()} €",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSmallResultCard(
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          prefixIcon: Icon(icon, color: const Color(0xFF0D71EE)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildSliderLabel(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
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

  Widget _buildResultCard({
    required String title,
    required String value,
    required String subtitle,
    bool isPrimary = false,
    Color? color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF0D71EE) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: const Color(0xFF0D71EE).withOpacity(0.3),
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
              color: isPrimary ? Colors.white70 : Colors.white60,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: isPrimary ? Colors.white60 : Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallResultCard({
    required String title,
    required String value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
