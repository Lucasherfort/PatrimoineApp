import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/investments/user_investment_account_view.dart';
import '../services/financial_profile_manager.dart';
import '../services/patrimoine_service.dart';
import '../models/patrimoine/patrimonial_indicator.dart';
import '../models/investments/estimated_gains_result.dart';
import '../services/theme_manager.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final PatrimoineService _patrimoineService = PatrimoineService();
  bool _isLoading = true;

  double _estimatedAnnualGains = 0.0;
  EstimatedGainsResult? _gainsDetails;
  PatrimonialIndicator? _crossingPoint;
  PatrimonialIndicator? _cruisingSpeed;

  final _formatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
    ThemeManager().addListener(_loadData);
    FinancialProfileManager().addListener(_loadData);
  }

  @override
  void dispose() {
    ThemeManager().removeListener(_loadData);
    FinancialProfileManager().removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final details = await _patrimoineService
          .getDetailedEstimatedAnnualGains();
      final crossing = await _patrimoineService.getCrossingPointIndicator();
      final cruising = await _patrimoineService.getCruisingSpeedIndicator();
      final accounts = await _patrimoineService
          .getInvestmentAccountsForUserWithPrices();

      if (mounted) {
        setState(() {
          _gainsDetails = details;
          _estimatedAnnualGains = details.totalGains;
          _crossingPoint = crossing;
          _cruisingSpeed = cruising;
          _investmentAccounts = accounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<UserInvestmentAccountView> _investmentAccounts = [];
  bool _showDiagnostic = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? theme.scaffoldBackgroundColor
            : const Color(0xFFF8FAFC),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0D71EE)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // --- BACKGROUND HALOS ---
          Positioned(
            top: -50,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF0D71EE,
                ).withValues(alpha: isDark ? 0.12 : 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
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
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.white,
              backgroundColor: const Color(0xFF0D71EE),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with Net/Gross pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ANALYSE",
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
                              "Performances",
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
                        _buildNetGrossBadge(context),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Main Hero Metric (Monthly Gain focus)
                    _buildPerformanceHero(context),

                    const SizedBox(height: 32),

                    // Independence Section Title
                    Row(
                      children: [
                        Text(
                          "PROJECTION D'INDÉPENDANCE",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.black38,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Compact Tiles for Independence
                    if (_crossingPoint != null && _cruisingSpeed != null)
                      Column(
                        children: [
                          _buildModernIndicatorTile(
                            context,
                            indicator: _crossingPoint!,
                            icon: Icons.sync_alt_rounded,
                            color: const Color(0xFF0D71EE),
                            label: "Point de croisement",
                            subLabel: "Couverture de l'investissement",
                          ),
                          const SizedBox(height: 12),
                          _buildModernIndicatorTile(
                            context,
                            indicator: _cruisingSpeed!,
                            icon: Icons.sailing_rounded,
                            color: const Color(0xFF8B5CF6),
                            label: "Chiffre de croisière",
                            subLabel: "Couverture du salaire net",
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // Diagnostic Link (Ultra discreet)
                    if (_estimatedAnnualGains == 0 &&
                        _investmentAccounts.isNotEmpty)
                      Center(
                        child: TextButton(
                          onPressed: () => setState(
                            () => _showDiagnostic = !_showDiagnostic,
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange.shade400.withValues(
                              alpha: 0.8,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: Text(
                            _showDiagnostic
                                ? "Masquer détails"
                                : "Détails du calcul (0€)",
                          ),
                        ),
                      ),

                    if (_showDiagnostic) _buildDiagnosticSection(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetGrossBadge(BuildContext context) {
    final isNet = ThemeManager().displayNetWealth;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isNet ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isNet ? "NET ESTIMÉ" : "BRUT TOTAL",
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white60 : Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceHero(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthlyGains = _estimatedAnnualGains / 12;

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
            "GAINS MENSUELS ESTIMÉS",
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
              _formatter.format(monthlyGains),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D71EE).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 12,
                  color: Color(0xFF0D71EE),
                ),
                const SizedBox(width: 8),
                Text(
                  "Soit ${_formatter.format(_estimatedAnnualGains)} / an",
                  style: const TextStyle(
                    color: Color(0xFF0D71EE),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (_estimatedAnnualGains == 0)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _getGainsExplanation(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange.shade400,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernIndicatorTile(
    BuildContext context, {
    required PatrimonialIndicator indicator,
    required IconData icon,
    required Color color,
    required String label,
    required String subLabel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subLabel,
                      style: TextStyle(
                        color: isDark ? Colors.white24 : Colors.black26,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (indicator.isCalculable)
                Text(
                  "${indicator.progression.toInt()}%",
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          if (indicator.isCalculable) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: (indicator.progression / 100).clamp(0.0, 1.0),
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildValueInfo(
                  "Actuel",
                  _formatter.format(indicator.currentValue),
                  isDark,
                ),
                _buildValueInfo(
                  "Cible",
                  "${_formatter.format(indicator.targetValue)}/an",
                  isDark,
                ),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                "Profil financier incomplet dans les paramètres.",
                style: TextStyle(
                  color: Colors.orange.shade400,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildValueInfo(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white24 : Colors.black26,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  String _getGainsExplanation() {
    if (_gainsDetails == null) return "Calcul en cours...";
    if (_gainsDetails!.totalAccounts == 0) return "Aucun compte détecté.";
    if (_gainsDetails!.hasMissingDates) {
      return "Vérifiez les dates d'ouverture de vos comptes.";
    }
    if (_gainsDetails!.hasRecentAccounts) {
      return "Comptes trop récents pour estimer un rendement.";
    }
    if (_gainsDetails!.calculableAccounts == 0) {
      return "Données historiques insuffisantes.";
    }
    return "Estimation nulle basée sur vos données.";
  }

  Widget _buildDiagnosticSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.orange.withValues(alpha: 0.05)
            : Colors.orange.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "DIAGNOSTIC TECHNIQUE",
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          ..._investmentAccounts.map((acc) {
            final double? ret = _patrimoineService
                .calculateAnnualizedReturnForAccount(acc);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${acc.bankName} (${acc.sourceName})",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    ret != null
                        ? "${(ret * 100).toStringAsFixed(1)}%"
                        : "Bloqué",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: ret != null ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
