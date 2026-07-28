import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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
    FinancialProfileManager().addListener(_onProfileChanged);
  }

  void _onProfileChanged() {
    final manager = FinancialProfileManager();
    if (mounted) {
      setState(() {
        if (manager.monthlyNetSalary > 0) {
          _salaryController.text = manager.monthlyNetSalary.toStringAsFixed(0);
        }
      });
    }
  }

  Future<void> _loadPatrimoine() async {
    try {
      final value = await PatrimoineService().getNetPatrimoine();
      final financialProfile = FinancialProfileManager();

      if (mounted) {
        setState(() {
          _netPatrimoine = value;
          _downPaymentController.text = (_netPatrimoine * 0.8).toStringAsFixed(
            0,
          );
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
    FinancialProfileManager().removeListener(_onProfileChanged);
    super.dispose();
  }

  // --- CALCULS ---
  double get _monthlySalary => double.tryParse(_salaryController.text) ?? 0;
  double get _downPayment => double.tryParse(_downPaymentController.text) ?? 0;
  double get _maxMonthlyPayment => _monthlySalary * 0.35;
  double get _borrowingCapacity {
    if (_maxMonthlyPayment <= 0) return 0;
    double monthlyRate = (_interestRate + _insuranceRate) / 100 / 12;
    double numMonths = _loanDurationYears * 12;
    if (monthlyRate == 0) return _maxMonthlyPayment * numMonths;
    return _maxMonthlyPayment *
        (pow(1 + monthlyRate, numMonths) - 1) /
        (monthlyRate * pow(1 + monthlyRate, numMonths));
  }

  double get _maxPropertyPrice => (_borrowingCapacity + _downPayment) / 1.075;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Impossible d\'ouvrir : $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color colorBlue = Color(0xFF0D71EE);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF060B26)
            : const Color(0xFFF8FAFC),
        body: const Center(child: CircularProgressIndicator(color: colorBlue)),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF060B26)
          : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // --- EFFET DE FOND (Halos) ---
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorBlue.withValues(alpha: isDark ? 0.10 : 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorBlue.withValues(alpha: isDark ? 0.06 : 0.04),
              ),
            ),
          ),

          // --- CONTENU PRINCIPAL ---
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with Net/Gross status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "IMMOBILIER",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : Colors.black38,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            "Simulateur",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Modern Hero Header (Purchase Capacity)
                  _buildHeroHeader(context),

                  const SizedBox(height: 32),

                  // Section Inputs: Vos Données
                  _buildSectionHeader(context, "VOTRE PROFIL FINANCIER"),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactInput(
                          context,
                          label: "Salaire Net",
                          controller: _salaryController,
                          icon: Icons.payments_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCompactInput(
                          context,
                          label: "Apport Perso.",
                          controller: _downPaymentController,
                          icon: Icons.savings_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section Inputs: Paramètres Crédit
                  _buildSectionHeader(context, "PARAMÈTRES DU PRÊT"),
                  _buildCompactSlider(
                    context,
                    label: "Durée",
                    value: _loanDurationYears,
                    min: 5,
                    max: 30,
                    divisions: 5,
                    suffix: "ans",
                    onChanged: (val) =>
                        setState(() => _loanDurationYears = val),
                  ),
                  const SizedBox(height: 8),
                  _buildCompactSlider(
                    context,
                    label: "Taux",
                    value: _interestRate,
                    min: 0.5,
                    max: 6.0,
                    divisions: 55,
                    suffix: "%",
                    onChanged: (val) => setState(() => _interestRate = val),
                  ),

                  const SizedBox(height: 24),

                  // Resources Section
                  _buildSectionHeader(context, "EXPLORER LE MARCHÉ"),
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildMarketTile(
                          context,
                          "Jinka",
                          "Alertes immo",
                          "https://www.jinka.fr/",
                          Icons.notifications_active_outlined,
                        ),
                        _buildMarketTile(
                          context,
                          "SeLoger",
                          "Annonces",
                          "https://www.seloger.com/",
                          Icons.search_rounded,
                        ),
                        _buildMarketTile(
                          context,
                          "Bien'ici",
                          "Carte immo",
                          "https://www.bienici.com/",
                          Icons.map_outlined,
                        ),
                        _buildMarketTile(
                          context,
                          "Castorus",
                          "Prix histo.",
                          "https://www.castorus.com/",
                          Icons.history_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black38,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCompactInput(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.02),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0D71EE), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            Text(
              "${value % 1 == 0 ? value.toInt() : value.toStringAsFixed(1)} $suffix",
              style: const TextStyle(
                color: Color(0xFF0D71EE),
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: const Color(0xFF0D71EE),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildMarketTile(
    BuildContext context,
    String title,
    String subtitle,
    String url,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.02),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF0D71EE), size: 20),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "CAPACITÉ D'ACHAT MAXIMALE",
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF0D71EE), Color(0xFF67C6F2)],
            ).createShader(bounds),
            child: Text(
              _formatter.format(_maxPropertyPrice),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCompactSubStat(
                context,
                "Mensualité",
                "${_maxMonthlyPayment.toInt()} €",
              ),
              Container(
                width: 1,
                height: 24,
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
              _buildCompactSubStat(
                context,
                "Prêt Max",
                _formatter.format(_borrowingCapacity),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSubStat(
    BuildContext context,
    String label,
    String value,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white24 : Colors.black26,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
