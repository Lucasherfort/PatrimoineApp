import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/investments/user_investment_account_view.dart';
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
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final details = await _patrimoineService.getDetailedEstimatedAnnualGains();
      final crossing = await _patrimoineService.getCrossingPointIndicator();
      final cruising = await _patrimoineService.getCruisingSpeedIndicator();
      final accounts = await _patrimoineService.getInvestmentAccountsForUserWithPrices();

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
        backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAFC),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0D71EE)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // --- BACKGROUND HALOS ---
          Positioned(
            top: -100,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0D71EE).withValues(alpha: isDark ? 0.10 : 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0D71EE).withValues(alpha: isDark ? 0.06 : 0.04),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ANALYSE",
                              style: TextStyle(
                                color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black38,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              "Performances",
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (_estimatedAnnualGains > 0)
                          _buildMiniBadge(
                            context,
                            icon: Icons.auto_graph,
                            label: "En croissance",
                            color: const Color(0xFF0D71EE),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Performance Card (Ultra Compact)
                    _buildPerformanceCard(context),

                    const SizedBox(height: 24),

                    // Independence Section Title
                    Row(
                      children: [
                        Text(
                          "INDÉPENDANCE FINANCIÈRE",
                          style: TextStyle(
                            color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black38,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Compact Indicator Cards
                    if (_crossingPoint != null)
                      _buildCompactIndicator(
                        context,
                        indicator: _crossingPoint!,
                        icon: Icons.sync_alt,
                        color: const Color(0xFF0D71EE),
                        targetLabel: "Invest. annuels",
                      ),

                    const SizedBox(height: 12),

                    if (_cruisingSpeed != null)
                      _buildCompactIndicator(
                        context,
                        indicator: _cruisingSpeed!,
                        icon: Icons.sailing_rounded,
                        color: const Color(0xFF8B5CF6),
                        targetLabel: "Salaire annuel",
                      ),

                    const SizedBox(height: 20),

                    // Diagnostic Link (Small)
                    if (_estimatedAnnualGains == 0 && _investmentAccounts.isNotEmpty)
                      Center(
                        child: InkWell(
                          onTap: () => setState(() => _showDiagnostic = !_showDiagnostic),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _showDiagnostic ? Icons.expand_less : Icons.troubleshoot_rounded,
                                  size: 16,
                                  color: Colors.orange.shade400,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _showDiagnostic ? "Masquer le diagnostic" : "Pourquoi 0€ ?",
                                  style: TextStyle(
                                    color: Colors.orange.shade400,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildPerformanceCard(BuildContext context) {
    final isNet = ThemeManager().displayNetWealth;
    final monthlyGains = _estimatedAnnualGains / 12;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D71EE), Color(0xFF0D5ED4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D71EE).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isNet ? "GAINS ESTIMÉS (NETS)" : "GAINS ESTIMÉS (BRUTS)",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  "${_formatter.format(monthlyGains)} / mois",
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatter.format(_estimatedAnnualGains),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 4),
          if (_estimatedAnnualGains == 0)
            Text(
              _getGainsExplanation(),
              style: TextStyle(color: Colors.orangeAccent.shade100, fontSize: 11, fontWeight: FontWeight.bold),
            )
          else
            Text(
              "Projection annuelle basée sur l'historique.",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactIndicator(
    BuildContext context, {
    required PatrimonialIndicator indicator,
    required IconData icon,
    required Color color,
    required String targetLabel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Text(
                indicator.name.toUpperCase(),
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black45,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              if (indicator.isCalculable)
                Text(
                  "${indicator.progression.toInt()}%",
                  style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900),
                )
              else
                const Icon(Icons.help_outline, size: 14, color: Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          if (indicator.isCalculable) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (indicator.progression / 100).clamp(0.0, 1.0),
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCompactValue("Gains", indicator.currentValue, color),
                _buildCompactValue(targetLabel, indicator.targetValue, isDark ? Colors.white70 : Colors.black87),
              ],
            ),
          ] else
            Text(
              "Profil incomplet dans les paramètres.",
              style: TextStyle(color: Colors.orange.shade400, fontSize: 11, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactValue(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
        Text(_formatter.format(value), style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildMiniBadge(BuildContext context, {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getGainsExplanation() {
    if (_gainsDetails == null) return "Données en cours de calcul...";
    if (_gainsDetails!.totalAccounts == 0) return "Aucun compte d'investissement.";
    if (_gainsDetails!.hasMissingDates) return "Dates d'ouverture manquantes.";
    if (_gainsDetails!.hasRecentAccounts) return "Comptes trop récents (<24h).";
    if (_gainsDetails!.calculableAccounts == 0) return "Données insuffisantes.";
    return "Estimation à 0€.";
  }

  Widget _buildDiagnosticSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.orange.withValues(alpha: 0.05) : Colors.orange.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("DIAGNOSTIC", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 10)),
          const SizedBox(height: 12),
          ..._investmentAccounts.map((acc) {
            final double? ret = _patrimoineService.calculateAnnualizedReturnForAccount(acc);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${acc.bankName} (${acc.sourceName})", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(ret != null ? "${(ret * 100).toStringAsFixed(1)}%" : "Bloqué", 
                       style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: ret != null ? Colors.green : Colors.red)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
