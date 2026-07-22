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
          // --- EFFET DE FOND (Halos) ---
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF0D71EE,
                ).withValues(alpha: isDark ? 0.12 : 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF0D71EE,
                ).withValues(alpha: isDark ? 0.08 : 0.05),
              ),
            ),
          ),

          // --- CONTENU PRINCIPAL ---
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.white,
              backgroundColor: const Color(0xFF0D71EE),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      "ANALYSE",
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.black45,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Performances & Projections",
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- CARTE PERFORMANCE ---
                    _buildPerformanceCard(context),

                    const SizedBox(height: 32),

                    Text(
                      "PROGRESSION DU PATRIMOINE",
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.black45,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- POINT DE CROISEMENT ---
                    if (_crossingPoint != null)
                      _buildIndicatorCard(
                        context,
                        indicator: _crossingPoint!,
                        icon: Icons.sync_alt,
                        color: const Color(0xFF0D71EE),
                        reachedDescription:
                            "Votre patrimoine génère désormais plus que ce que vous investissez chaque année.",
                        notReachedDescription:
                            "Votre patrimoine progresse vers le point où ses gains dépasseront vos investissements annuels.",
                        targetLabel: "Investissements annuels",
                        emptyStateMessage:
                            "Complétez votre profil financier pour calculer votre point de croisement.",
                      ),

                    const SizedBox(height: 16),

                    // --- CHIFFRE DE CROISIÈRE ---
                    if (_cruisingSpeed != null)
                      _buildIndicatorCard(
                        context,
                        indicator: _cruisingSpeed!,
                        icon: Icons.sailing,
                        color: Colors.purple,
                        reachedDescription:
                            "Votre patrimoine génère désormais davantage que votre salaire annuel.",
                        notReachedDescription:
                            "Votre patrimoine progresse vers le niveau où ses gains dépasseront votre salaire annuel.",
                        targetLabel: "Salaire annuel",
                        emptyStateMessage:
                            "Complétez votre profil financier pour calculer votre chiffre de croisière.",
                      ),

                    const SizedBox(height: 32),

                    // --- PLACEHOLDERS POUR LE FUTUR ---
                    _buildPlaceholderCard(
                      context,
                      title: "Fiscalité estimée",
                      icon: Icons.account_balance_wallet,
                    ),
                    _buildPlaceholderCard(
                      context,
                      title: "Projections FIRE",
                      icon: Icons.local_fire_department,
                    ),

                    const SizedBox(height: 32),

                    // --- BOUTON DIAGNOSTIC (Si gains à 0) ---
                    if (_estimatedAnnualGains == 0 &&
                        _investmentAccounts.isNotEmpty)
                      Center(
                        child: TextButton.icon(
                          onPressed: () => setState(
                            () => _showDiagnostic = !_showDiagnostic,
                          ),
                          icon: Icon(
                            _showDiagnostic
                                ? Icons.expand_less
                                : Icons.troubleshoot,
                            color: Colors.orangeAccent,
                          ),
                          label: Text(
                            _showDiagnostic
                                ? "Masquer le diagnostic"
                                : "Pourquoi mes gains sont à 0€ ?",
                            style: const TextStyle(color: Colors.orangeAccent),
                          ),
                        ),
                      ),

                    if (_showDiagnostic) _buildDiagnosticSection(context),

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

  Widget _buildDiagnosticSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.orange.withValues(alpha: 0.05)
            : Colors.orange.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "DIAGNOSTIC DES DONNÉES",
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          ..._investmentAccounts.map((acc) {
            final double? ret = _patrimoineService
                .calculateAnnualizedReturnForAccount(acc);
            final int age = acc.openedAt != null
                ? DateTime.now().difference(acc.openedAt!).inDays
                : 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${acc.bankName} - ${acc.sourceName}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                  if (ret != null)
                    _buildDiagnosticRow(
                      "Rendement calc.",
                      "${(ret * 100).toStringAsFixed(2)} %",
                      color: Colors.green,
                    )
                  else
                    _buildDiagnosticRow(
                      "Raison blocage",
                      acc.openedAt == null
                          ? "Date manquante"
                          : (age < 1 ? "Moins de 24h" : "Versements à 0€"),
                      color: Colors.red,
                    ),
                  const Divider(height: 16),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(BuildContext context) {
    final isNet = ThemeManager().displayNetWealth;
    final monthlyGains = _estimatedAnnualGains / 12;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D71EE), Color(0xFF004CB3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D71EE).withValues(alpha: 0.3),
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
              Icon(
                Icons.auto_graph,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isNet
                      ? "GAINS ANNUELS ESTIMÉS (NETS)"
                      : "GAINS ANNUELS ESTIMÉS (BRUTS)",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _formatter.format(_estimatedAnnualGains),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${_formatter.format(monthlyGains)} / mois",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _estimatedAnnualGains > 0
                ? "Basé sur le rendement historique de vos comptes d'investissement."
                : _getGainsExplanation(),
            style: TextStyle(
              color: _estimatedAnnualGains > 0
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.orangeAccent,
              fontSize: 12,
              fontWeight: _estimatedAnnualGains > 0
                  ? FontWeight.normal
                  : FontWeight.bold,
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
      return "Certaines dates d'ouverture sont manquantes. Vérifiez vos comptes.";
    }
    if (_gainsDetails!.hasRecentAccounts) {
      return "Vos comptes sont trop récents (moins de 24h) pour calculer un rendement.";
    }
    if (_gainsDetails!.calculableAccounts == 0) {
      return "Données insuffisantes sur vos comptes pour estimer les gains.";
    }
    return "Estimation à 0€ sur la base de vos données actuelles.";
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? null
            : Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      indicator.name.toUpperCase(),
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          indicator.isReached
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 16,
                          color: indicator.isReached
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          indicator.isReached ? "Atteint" : "Non atteint",
                          style: TextStyle(
                            color: indicator.isReached
                                ? Colors.green
                                : Colors.red,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (indicator.isCalculable)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Progression",
                      style: TextStyle(
                        color: isDark ? Colors.white24 : Colors.black26,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${indicator.progression.toInt()}%",
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (indicator.isCalculable) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (indicator.progression / 100).clamp(0.0, 1.0),
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isNet
                            ? "Gains annuels (nets)"
                            : "Gains annuels (bruts)",
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatter.format(indicator.currentValue),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        targetLabel,
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatter.format(indicator.targetValue),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      emptyStateMessage,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(
            indicator.isReached ? reachedDescription : notReachedDescription,
            style: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 11,
              fontStyle: FontStyle.italic,
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
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? null
            : Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.grey, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                Text(
                  "Bientôt disponible",
                  style: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black26,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
