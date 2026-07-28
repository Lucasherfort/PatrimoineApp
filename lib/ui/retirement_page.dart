import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/financial_profile_manager.dart';
import '../services/patrimoine_service.dart';

class RetirementPage extends StatefulWidget {
  const RetirementPage({super.key});

  @override
  State<RetirementPage> createState() => _RetirementPageState();
}

class _RetirementPageState extends State<RetirementPage> {
  final PatrimoineService _patrimoineService = PatrimoineService();
  final _formatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 0,
  );

  double _currentWealth = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentWealth();
  }

  Future<void> _loadCurrentWealth() async {
    try {
      final wealth = await _patrimoineService.getPatrimoineGross();
      if (mounted) {
        setState(() {
          _currentWealth = wealth;
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
        backgroundColor: theme.scaffoldBackgroundColor,
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
          Positioned(
            bottom: 50,
            left: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF0D71EE,
                ).withValues(alpha: isDark ? 0.08 : 0.04),
              ),
            ),
          ),

          // --- MAIN CONTENT ---
          SafeArea(
            child: ListenableBuilder(
              listenable: FinancialProfileManager(),
              builder: (context, child) {
                final manager = FinancialProfileManager();

                // Data presence check
                if (manager.retirementDesiredIncome <= 0 ||
                    manager.retirementEstimatedPension <= 0) {
                  return _buildEmptyState(isDark);
                }

                // Calculations
                final double incomeToFinance =
                    (manager.retirementDesiredIncome -
                            manager.retirementEstimatedPension)
                        .clamp(0.0, double.infinity);
                final double targetWealth = incomeToFinance > 0
                    ? incomeToFinance / (manager.retirementSwr / 100)
                    : 0.0;

                final double remainingToBuild = (targetWealth - _currentWealth)
                    .clamp(0.0, double.infinity);
                final double progression = targetWealth > 0
                    ? (_currentWealth / targetWealth).clamp(0.0, 1.0)
                    : 1.0;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header (Compact)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "RETRAITE & FIRE",
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
                                "Objectif Liberté",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.wb_sunny_rounded,
                            color: const Color(
                              0xFF0D71EE,
                            ).withValues(alpha: 0.2),
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Simulations en brut annuel.",
                        style: TextStyle(
                          color: isDark ? Colors.white24 : Colors.black26,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Card 1: Revenus (More compact)
                      _buildSummaryCard(
                        context,
                        title: "VOS REVENUS",
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              "Revenu souhaité",
                              _formatter.format(
                                manager.retirementDesiredIncome,
                              ),
                              isDark,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              "Pension estimée",
                              _formatter.format(
                                manager.retirementEstimatedPension,
                              ),
                              isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Card 2 & 3: Merged into a denser section
                      _buildSummaryCard(
                        context,
                        title: "BESOIN & CIBLE",
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "À FINANCER",
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white24
                                              : Colors.black26,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatter.format(incomeToFinance),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.black.withValues(alpha: 0.05),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "CAPITAL CIBLE",
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white24
                                              : Colors.black26,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatter.format(targetWealth),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0D71EE),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (incomeToFinance > 0) ...[
                              const SizedBox(height: 12),
                              Text(
                                "Avec un taux de ${manager.retirementSwr.toStringAsFixed(1)}%, ce capital génère ${_formatter.format(incomeToFinance)} / an.",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black45,
                                  fontSize: 10,
                                  height: 1.4,
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 12),
                              Text(
                                "Votre pension couvre déjà votre objectif.",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Card 4: Progression (Compressed)
                      _buildSummaryCard(
                        context,
                        title: "PROGRESSION",
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMiniStat(
                                  "Actuel",
                                  _formatter.format(_currentWealth),
                                  isDark,
                                ),
                                _buildMiniStat(
                                  "Objectif",
                                  _formatter.format(targetWealth),
                                  isDark,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: LinearProgressIndicator(
                                value: progression,
                                minHeight: 6,
                                backgroundColor: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF0D71EE),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${(progression * 100).toInt()}% atteint",
                                  style: const TextStyle(
                                    color: Color(0xFF0D71EE),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                if (remainingToBuild > 0)
                                  Text(
                                    "Reste : ${_formatter.format(remainingToBuild)}",
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.black38,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    String? highlightValue,
    String? infoText,
    Widget? child,
    bool showCheck = false,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.02),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              if (showCheck)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 18,
                ),
            ],
          ),
          if (highlightValue != null) ...[
            const SizedBox(height: 12),
            Text(
              highlightValue,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
            ),
          ],
          if (infoText != null) ...[
            const SizedBox(height: 8),
            Text(
              infoText,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black45,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          if (child != null) child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white24 : Colors.black38,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_fix_high_rounded,
              size: 48,
              color: const Color(0xFF0D71EE).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              "Complétez vos préférences retraite afin d'estimer votre patrimoine cible.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
