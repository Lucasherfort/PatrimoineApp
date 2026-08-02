import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/patrimoine_service.dart';
import '../services/budget_service.dart';
import '../services/financial_profile_manager.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final PatrimoineService _patrimoineService = PatrimoineService();
  final BudgetService _budgetService = BudgetService();

  final _formatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 0,
  );

  bool _isLoading = true;

  // Data
  double _passiveGains = 0;
  double _totalExpenses = 0;
  double _essentialExpenses = 0;
  double _savingsCapacity = 0;
  double _liquidAssets = 0;
  double _totalWealth = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final annualGains = await _patrimoineService
          .getEstimatedAnnualInvestmentGains();
      final expenses = await _budgetService.getTotalOutgoings();
      final essentials = await _budgetService.getTotalEssentialExpenses();
      final savingsCap = await _budgetService.getMonthlySavingsCapacity();

      // For Safety Cape: Liquidities + Savings
      final netWealth = await _patrimoineService.getNetPatrimoine();
      // Note: getNetPatrimoine is liquid + savings + invested capital
      // We might want just liquid + savings for safety
      final invested = await _patrimoineService.getTotalInvestedCapital();
      final safetyBuffer = netWealth - invested;

      if (mounted) {
        setState(() {
          _passiveGains = annualGains / 12;
          _totalExpenses = expenses;
          _essentialExpenses = essentials;
          _savingsCapacity = savingsCap;
          _liquidAssets = safetyBuffer;
          _totalWealth = netWealth;
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
                    const SizedBox(height: 32),

                    // 1. Point d'équilibre patrimonial
                    _buildIndicatorCard(
                      title: "ÉQUILIBRE PATRIMONIAL",
                      subtitle: "Gains vs Dépenses essentielles",
                      current: _passiveGains,
                      target: _essentialExpenses,
                      icon: Icons.balance_rounded,
                      color: Colors.blue,
                      unit: "€/mois",
                    ),
                    const SizedBox(height: 16),

                    // 2. Cap de sécurité
                    _buildIndicatorCard(
                      title: "CAP DE SÉCURITÉ",
                      subtitle: "Mois de dépenses d'avance",
                      current: _totalExpenses > 0
                          ? _liquidAssets / _totalExpenses
                          : 0,
                      target: 6, // Objectif standard 6 mois
                      icon: Icons.shield_outlined,
                      color: Colors.orange,
                      unit: "mois",
                      isRatio: true,
                    ),
                    const SizedBox(height: 16),

                    // 3. Cap de liberté
                    _buildIndicatorCard(
                      title: "CAP DE LIBERTÉ",
                      subtitle: "Indépendance financière totale",
                      current: _passiveGains,
                      target: _totalExpenses,
                      icon: Icons.sailing_rounded,
                      color: Colors.purple,
                      unit: "€/mois",
                    ),
                    const SizedBox(height: 16),

                    // 4. Point d'accélération
                    _buildIndicatorCard(
                      title: "POINT D'ACCÉLÉRATION",
                      subtitle: "Gains passifs vs Effort d'épargne",
                      current: _passiveGains,
                      target: _savingsCapacity.clamp(1.0, double.infinity),
                      icon: Icons.rocket_launch_outlined,
                      color: Colors.redAccent,
                      unit: "€/mois",
                    ),
                    const SizedBox(height: 16),

                    // 5. Indice d'indépendance
                    _buildIndiceCard(isDark),
                    const SizedBox(height: 16),

                    // 6. Horizon d'autonomie
                    _buildHorizonCard(isDark),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
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
                child: Icon(icon, color: color, size: 20),
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
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Actuel",
                    style: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isRatio
                        ? current.toStringAsFixed(1)
                        : _formatter.format(current),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
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
                    isRatio
                        ? "$target $unit"
                        : "${_formatter.format(target)} /mois",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progression,
              minHeight: 6,
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

  Widget _buildIndiceCard(bool isDark) {
    final double indice = _totalExpenses > 0
        ? (_passiveGains / _totalExpenses) * 100
        : 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D71EE), Color(0xFF0D5ED4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "INDICE D'INDÉPENDANCE",
            style: TextStyle(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                "${indice.toInt()}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  "de vos dépenses totales sont couvertes par vos revenus passifs.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorizonCard(bool isDark) {
    // Horizon calculation: very simplified
    // If savings capacity is positive, we assume it's invested at a certain rate (ex 5%)
    // and we find when wealth * rate / 12 >= totalExpenses

    int years = 0;
    if (_savingsCapacity > 0) {
      double simulatedWealth = _totalWealth;
      const double yield = 0.05; // 5% cautious yield
      while (simulatedWealth * (yield / 12) < _totalExpenses && years < 50) {
        simulatedWealth =
            (simulatedWealth + (_savingsCapacity * 12)) * (1 + yield);
        years++;
      }
    } else {
      years = 99; // Impossible horizon
    }

    final String horizonText = years >= 50 ? "Indéfini" : "$years ans";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "HORIZON D'AUTONOMIE",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  "Basé sur votre épargne actuelle",
                  style: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black26,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            horizonText,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Color(0xFF0D71EE),
            ),
          ),
        ],
      ),
    );
  }
}
