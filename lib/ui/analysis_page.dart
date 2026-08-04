import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/patrimoine_service.dart';
import '../services/financial_profile_manager.dart';
import '../services/data_sync_service.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final PatrimoineService _patrimoineService = PatrimoineService();

  final _formatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 0,
  );

  bool _isLoading = true;

  // Data
  double _passiveGains = 0;
  double _monthlyInvestment = 0;
  double _monthlyNetSalary = 0;
  double _totalWealth = 0;

  // Asset Allocation
  double _totalLiquidity = 0;
  double _totalSavings = 0;
  double _totalInvestments = 0;

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

      final netWealth = await _patrimoineService.getNetPatrimoine();

      // Fetch components for allocation chart
      final results = await Future.wait([
        _patrimoineService.getLiquidityValue(),
        _patrimoineService.getSavingsValue(),
        _patrimoineService.getInvestmentsValue(),
      ]);

      if (mounted) {
        setState(() {
          _passiveGains = annualGains / 12;
          _monthlyInvestment = monthlyInv;
          _monthlyNetSalary = monthlySalary;
          _totalWealth = netWealth;
          _totalLiquidity = results[0];
          _totalSavings = results[1];
          _totalInvestments = results[2];
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

                    // Allocation Chart
                    if (_totalWealth > 0) ...[
                      _buildAllocationChart(isDark),
                      const SizedBox(height: 28),
                    ],

                    // 1. Couverture du DCA (Point de croisement)
                    _buildIndicatorCard(
                      title: "COUVERTURE DE L'INVESTISSEMENT",
                      subtitle: "Gains passifs vs Montant investi (DCA)",
                      current: _passiveGains,
                      target: _monthlyInvestment.clamp(1.0, double.infinity),
                      icon: Icons.sync_alt_rounded,
                      color: const Color(0xFF0D71EE),
                      unit: "€/mois",
                    ),
                    const SizedBox(height: 20),

                    // 2. Couverture du Salaire
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
              _formatter.format(_passiveGains),
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
    return Column(
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
    );
  }

  Widget _buildAllocationChart(bool isDark) {
    final Map<String, double> allocation = {
      "Liquidités": _totalLiquidity,
      "Épargne": _totalSavings,
      "Investissements": _totalInvestments,
    };

    final List<Color> colors = [
      const Color(0xFF0D71EE), // Liquidités
      const Color(0xFF8B5CF6), // Épargne
      const Color(0xFF10B981), // Investissements
    ];

    final sortedEntries = allocation.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final double totalAllocation = sortedEntries.fold(
      0.0,
      (sum, e) => sum + e.value,
    );

    return Container(
      height: 145,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.02),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 30,
                sections: sortedEntries.asMap().entries.map((entry) {
                  final value = entry.value.value;
                  final percentage = totalAllocation > 0
                      ? (value / totalAllocation * 100)
                      : 0;

                  int colorIndex = 0;
                  if (entry.value.key == "Épargne") colorIndex = 1;
                  if (entry.value.key == "Investissements") colorIndex = 2;

                  return PieChartSectionData(
                    color: colors[colorIndex],
                    value: value,
                    title: percentage >= 15 ? '${percentage.toInt()}%' : '',
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sortedEntries.asMap().entries.map((entry) {
                int colorIndex = 0;
                if (entry.value.key == "Épargne") colorIndex = 1;
                if (entry.value.key == "Investissements") colorIndex = 2;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: colors[colorIndex],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.value.key,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatter.format(entry.value.value),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
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
                    isRatio ? "$target $unit" : _formatter.format(target),
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
