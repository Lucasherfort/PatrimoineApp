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
            top: -120,
            right: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF0D71EE,
                ).withValues(alpha: isDark ? 0.12 : 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -150,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF0D71EE,
                ).withValues(alpha: isDark ? 0.08 : 0.05),
              ),
            ),
          ),

          // --- MAIN CONTENT ---
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.white,
              backgroundColor: const Color(0xFF0D71EE),
              edgeOffset: 20,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ANALYSE",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.black38,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Performances & Projections",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Performance Card
                    _buildPerformanceCard(context),

                    const SizedBox(height: 40),

                    // Progress Section Title
                    Row(
                      children: [
                        Text(
                          "PROGRESSION DU PATRIMOINE",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.black38,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Point de croisement
                    if (_crossingPoint != null)
                      _buildIndicatorCard(
                        context,
                        indicator: _crossingPoint!,
                        icon: Icons.sync_alt,
                        color: const Color(0xFF0D71EE),
                        reachedDescription:
                            "Vos gains couvrent vos investissements annuels.",
                        notReachedDescription:
                            "Objectif : couvrir vos investissements annuels.",
                        targetLabel: "Investissements annuels",
                        emptyStateMessage:
                            "Complétez votre profil financier pour voir ce seuil.",
                      ),

                    const SizedBox(height: 20),

                    // Chiffre de croisière
                    if (_cruisingSpeed != null)
                      _buildIndicatorCard(
                        context,
                        indicator: _cruisingSpeed!,
                        icon: Icons.sailing_rounded,
                        color: const Color(0xFF8B5CF6), // Soft Purple
                        reachedDescription:
                            "Vos gains couvrent votre salaire annuel net.",
                        notReachedDescription:
                            "Objectif : couvrir votre salaire annuel net.",
                        targetLabel: "Salaire annuel",
                        emptyStateMessage:
                            "Complétez votre profil financier pour voir ce seuil.",
                      ),

                    const SizedBox(height: 40),

                    // Upcoming Features
                    Text(
                      "À VENIR",
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.black38,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPlaceholderCard(
                      context,
                      title: "Projections FIRE",
                      icon: Icons.local_fire_department_outlined,
                      subtitle: "Simulation de votre date de retraite",
                    ),

                    const SizedBox(height: 32),

                    // Diagnostic Button
                    if (_estimatedAnnualGains == 0 &&
                        _investmentAccounts.isNotEmpty)
                      Center(
                        child: TextButton.icon(
                          onPressed: () => setState(
                            () => _showDiagnostic = !_showDiagnostic,
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange.shade400,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            _showDiagnostic
                                ? Icons.expand_less
                                : Icons.troubleshoot_rounded,
                            size: 20,
                          ),
                          label: Text(
                            _showDiagnostic
                                ? "Masquer le diagnostic"
                                : "Pourquoi mes gains sont à 0€ ?",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                    if (_showDiagnostic) _buildDiagnosticSection(context),

                    const SizedBox(height: 60),
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D71EE), Color(0xFF0D5ED4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D71EE).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.auto_graph,
              size: 100,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        isNet
                            ? "GAINS ESTIMÉS (NETS)"
                            : "GAINS ESTIMÉS (BRUTS)",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        "${_formatter.format(monthlyGains)} / mois",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _formatter.format(_estimatedAnnualGains),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Projection annuelle estimée",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _estimatedAnnualGains > 0
                            ? Icons.lightbulb_outline
                            : Icons.info_outline,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 14,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _estimatedAnnualGains > 0
                              ? "Basé sur l'historique de vos investissements."
                              : _getGainsExplanation(),
                          style: TextStyle(
                            color: _estimatedAnnualGains > 0
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.orangeAccent.shade100,
                            fontSize: 11,
                            fontWeight: _estimatedAnnualGains > 0
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGainsExplanation() {
    if (_gainsDetails == null) return "Données en cours de calcul...";
    if (_gainsDetails!.totalAccounts == 0) {
      return "Aucun compte d'investissement détecté.";
    }
    if (_gainsDetails!.hasMissingDates) {
      return "Dates d'ouverture manquantes. Vérifiez vos comptes.";
    }
    if (_gainsDetails!.hasRecentAccounts) {
      return "Comptes trop récents pour calculer un rendement.";
    }
    if (_gainsDetails!.calculableAccounts == 0) {
      return "Données insuffisantes pour estimer les gains.";
    }
    return "Estimation à 0€ avec les données actuelles.";
  }

  Widget _buildIndicatorCard(
    BuildContext context, {
    required PatrimonialIndicator indicator,
    required IconData icon,
    required Color color,
    required String reachedDescription,
    required String notReachedDescription,
    required String targetLabel,
    required String emptyStateMessage,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final isNet = ThemeManager().displayNetWealth;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.05))
            : Border.all(color: Colors.black.withValues(alpha: 0.03)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      indicator.name.toUpperCase(),
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black45,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      indicator.isReached ? "Objectif atteint" : "En cours",
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (indicator.isReached)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (indicator.isCalculable) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isNet ? "Gains nets" : "Gains bruts",
                      style: TextStyle(
                        color: isDark ? Colors.white24 : Colors.black26,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatter.format(indicator.currentValue),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    "${indicator.progression.toInt()}%",
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (indicator.progression / 100).clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  targetLabel,
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black45,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "${_formatter.format(indicator.targetValue)} / an",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ] else
            _buildEmptyIndicatorState(emptyStateMessage),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              indicator.isReached ? reachedDescription : notReachedDescription,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black45,
                fontSize: 11,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyIndicatorState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white12 : Colors.black12,
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white10 : Colors.black12,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.orange.withValues(alpha: 0.05)
            : Colors.orange.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                "DIAGNOSTIC TECHNIQUE",
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._investmentAccounts.map((acc) {
            final double? ret = _patrimoineService
                .calculateAnnualizedReturnForAccount(acc);
            final int age = acc.openedAt != null
                ? DateTime.now().difference(acc.openedAt!).inDays
                : 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${acc.bankName} - ${acc.sourceName}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDiagnosticRow(
                    "Versements",
                    _formatter.format(acc.totalContribution),
                  ),
                  _buildDiagnosticRow(
                    "Valorisation",
                    _formatter.format(acc.amount),
                  ),
                  _buildDiagnosticRow(
                    "Ancienneté",
                    acc.openedAt == null ? "Non renseignée" : "$age jours",
                  ),
                  const SizedBox(height: 4),
                  if (ret != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _buildDiagnosticRow(
                        "Rendement calc.",
                        "${(ret * 100).toStringAsFixed(2)} %",
                        color: Colors.green,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _buildDiagnosticRow(
                        "Bloqué car",
                        acc.openedAt == null
                            ? "Date manquante"
                            : (age < 1
                                  ? "Compte trop récent"
                                  : "Versements à 0€"),
                        color: Colors.red,
                      ),
                    ),
                  if (acc != _investmentAccounts.last)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Divider(
                        color: Colors.orange.withValues(alpha: 0.1),
                        height: 1,
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

  Widget _buildDiagnosticRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
