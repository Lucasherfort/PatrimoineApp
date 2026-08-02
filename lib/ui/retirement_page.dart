import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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

  late TextEditingController _incomeController;
  late TextEditingController _pensionController;
  late TextEditingController _swrController;
  late TextEditingController _inflationController;

  double _currentWealth = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final manager = FinancialProfileManager();
    _incomeController = TextEditingController(
      text: manager.retirementDesiredIncome > 0
          ? manager.retirementDesiredIncome.toStringAsFixed(0)
          : '',
    );
    _pensionController = TextEditingController(
      text: manager.retirementEstimatedPension > 0
          ? manager.retirementEstimatedPension.toStringAsFixed(0)
          : '',
    );
    _swrController = TextEditingController(
      text: manager.retirementSwr.toStringAsFixed(1),
    );
    _inflationController = TextEditingController(
      text: manager.inflationRate.toStringAsFixed(1),
    );

    _loadCurrentWealth();
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _pensionController.dispose();
    _swrController.dispose();
    _inflationController.dispose();
    super.dispose();
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
                      // Header (Compact with Back Button)
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
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

                      // Card 1: VOS PARAMÈTRES (Interactive)
                      _buildSummaryCard(
                        context,
                        title: "VOS HYPOTHÈSES",
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildCompactInputField(
                              context,
                              label: "Revenu souhaité",
                              controller: _incomeController,
                              onChanged: (val) {
                                final d = double.tryParse(val) ?? 0.0;
                                manager.setRetirementDesiredIncome(d);
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildCompactInputField(
                                    context,
                                    label: "Pension estimée",
                                    controller: _pensionController,
                                    onChanged: (val) {
                                      final d = double.tryParse(val) ?? 0.0;
                                      manager.setRetirementEstimatedPension(d);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: _buildCompactInputField(
                                    context,
                                    label: "Taux",
                                    controller: _swrController,
                                    suffix: "%",
                                    onChanged: (val) {
                                      double d = double.tryParse(val) ?? 4.0;
                                      if (d < 3) d = 3.0;
                                      if (d > 5) d = 5.0;
                                      manager.setRetirementSwr(d);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Card 2 & 3: Merged into a denser section
                      if (manager.retirementDesiredIncome > 0)
                        Column(
                          children: [
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
                                              _formatter.format(
                                                incomeToFinance,
                                              ),
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
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Color(0xFF0D71EE),
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: _buildEmptyStateView(isDark),
                        ),
                      const SizedBox(height: 24),

                      // Resources Section
                      _buildSummaryCard(
                        context,
                        title: "RESSOURCES",
                        padding: const EdgeInsets.all(16),
                        child: InkWell(
                          onTap: () =>
                              _launchUrl("https://www.lassuranceretraite.fr/"),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.03)
                                  : Colors.black.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.language_rounded,
                                  color: Color(0xFF0D71EE),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "L'Assurance Retraite",
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        "Estimer ma pension sur le site officiel",
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white24
                                              : Colors.black38,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.open_in_new_rounded,
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.black12,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
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
          if (child != null) ...[const SizedBox(height: 12), child],
        ],
      ),
    );
  }

  Widget _buildCompactInputField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    String suffix = "€",
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: onChanged,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
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
          Text(
            suffix,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ],
      ),
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

  Widget _buildEmptyStateView(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Icon(
          Icons.auto_fix_high_rounded,
          size: 40,
          color: const Color(0xFF0D71EE).withValues(alpha: 0.3),
        ),
        const SizedBox(height: 16),
        Text(
          "Renseignez votre revenu souhaité pour projeter votre capital cible.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
