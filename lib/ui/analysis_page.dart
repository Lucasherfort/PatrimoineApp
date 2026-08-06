import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/patrimoine_service.dart';
import '../services/budget_service.dart';
import '../services/financial_profile_manager.dart';
import '../services/data_sync_service.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final PatrimoineService _patrimoineService = PatrimoineService();

  String _formatAmount(double amount, {bool includeSymbol = true}) {
    final formatter = NumberFormat("#,##0", "fr_FR");
    final formatted = formatter
        .format(amount)
        .replaceAll(RegExp(r'[\s\u00A0\u202F]'), '\u2007');
    return includeSymbol ? "$formatted €" : formatted;
  }

  bool _isLoading = true;

  // Data
  double _passiveGains = 0;
  double _totalExpenses = 0;
  double _monthlyInvestment = 0;
  double _monthlyNetSalary = 0;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    FinancialProfileManager().addListener(_loadAllData);
    DataSyncService().addListener(
      _loadAllData,
    ); // 👈 Écoute les mises à jour globales
  }

  @override
  void dispose() {
    FinancialProfileManager().removeListener(_loadAllData);
    DataSyncService().removeListener(_loadAllData); // 👈 Nettoyage
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final annualGains = await _patrimoineService
          .getEstimatedAnnualInvestmentGains();

      final manager = FinancialProfileManager();
      final monthlyInv = manager.monthlyInvestment;
      final monthlySalary = manager.monthlyNetSalary;

      await _patrimoineService.getNetPatrimoine();
      final expenses = await BudgetService().getTotalOutgoings();

      if (mounted) {
        setState(() {
          _passiveGains = annualGains / 12;
          _monthlyInvestment = monthlyInv;
          _monthlyNetSalary = monthlySalary;
          _totalExpenses = expenses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF060B26)
            : const Color(0xFFF8FAFC),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0D71EE)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF060B26)
          : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // --- BACKGROUND HALOS ---
          Positioned(
            top: -50,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF0D71EE,
                ).withValues(alpha: isDark ? 0.12 : 0.07),
              ),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadAllData,
              color: Colors.white,
              backgroundColor: const Color(0xFF0D71EE),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDark),
                    const SizedBox(height: 24),

                    // Gains Hero
                    _buildGainsHero(context),
                    const SizedBox(height: 28),

                    // 1. Couverture des dépenses
                    _buildIndicatorCard(
                      title: "COUVERTURE DES DÉPENSES",
                      subtitle: "Gains passifs vs Dépenses totales",
                      current: _passiveGains,
                      target: _totalExpenses.clamp(1.0, double.infinity),
                      icon: Icons.shopping_cart_outlined,
                      color: Colors.orange,
                      unit: "€/mois",
                    ),
                    const SizedBox(height: 16),

                    // 2. Couverture du DCA (Point de croisement)
                    _buildIndicatorCard(
                      title: "COUVERTURE DE L'INVESTISSEMENT",
                      subtitle: "Gains passifs vs Montant investi (DCA)",
                      current: _passiveGains,
                      target: _monthlyInvestment.clamp(1.0, double.infinity),
                      icon: Icons.sync_alt_rounded,
                      color: const Color(0xFF0D71EE),
                      unit: "€/mois",
                    ),
                    const SizedBox(height: 16),

                    // 3. Couverture du Salaire
                    _buildIndicatorCard(
                      title: "COUVERTURE DU SALAIRE",
                      subtitle: "Gains passifs vs Salaire net mensuel",
                      current: _passiveGains,
                      target: _monthlyNetSalary.clamp(1.0, double.infinity),
                      icon: Icons.payments_outlined,
                      color: const Color(0xFF8B5CF6),
                      unit: "€/mois",
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGainsHero(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        ),
      ),
      child: Column(
        children: [
          Text(
            "GAINS MENSUELS ESTIMÉS",
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF0D71EE), Color(0xFF67C6F2)],
            ).createShader(bounds),
            child: Text(
              _isVisible ? _formatAmount(_passiveGains) : "•••• €",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Moyenne générée par vos actifs",
            style: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ANALYSE STRATÉGIQUE",
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black38,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Pilote d'Indépendance",
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () => setState(() => _isVisible = !_isVisible),
          icon: Icon(
            _isVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: isDark ? Colors.white24 : Colors.black12,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorCard({
    required String title,
    required String subtitle,
    required double current,
    required double target,
    required IconData icon,
    required Color color,
    required String unit,
    bool isRatio = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double progression = target > 0
        ? (current / target).clamp(0.0, 1.0)
        : (current > 0 ? 1.0 : 0.0);
    final bool isReached = progression >= 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.02),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white24 : Colors.black26,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (isReached)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Progression",
                    style: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${(progression * 100).toInt()}%",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Objectif",
                    style: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _isVisible
                        ? (isRatio
                              ? "$target $unit"
                              : "${_formatAmount(target, includeSymbol: false)} $unit")
                        : "•• $unit",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progression,
              minHeight: 5,
              backgroundColor: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
