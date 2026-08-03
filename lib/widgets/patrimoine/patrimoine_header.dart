import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/theme_manager.dart';

class PatrimoineHeader extends StatefulWidget {
  final double patrimoineTotal;
  final double patrimoineNetEstimated; // 👈 Ajouté
  final double investedCapital;
  final double portfolioValue;
  final double netWorth;
  final double netPatrimoine;
  final double? historicalInvestmentValue; // 👈 Modifié
  final bool hasInvestments;

  const PatrimoineHeader({
    super.key,
    required this.patrimoineTotal,
    required this.patrimoineNetEstimated,
    required this.investedCapital,
    required this.portfolioValue,
    required this.netWorth,
    required this.netPatrimoine,
    this.historicalInvestmentValue, // 👈 Modifié
    this.hasInvestments = true,
  });

  @override
  State<PatrimoineHeader> createState() => _PatrimoineHeaderState();
}

class _PatrimoineHeaderState extends State<PatrimoineHeader> {
  bool _isVisible = true;

  static const Color colorGreenFlash = Color(0xFF65E046);
  static const Color colorGreenDark = Color(0xFF15803D);
  static const Color colorOrangeLogo = Color(0xFFD98006);
  static const Color colorOrangeDark = Color(0xFFC2410C);

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '',
      decimalDigits: 2,
    );

    return formatter.format(amount).trim();
  }

  // =========================
  // Calculs
  // =========================
  double get profitLoss => widget.portfolioValue - widget.investedCapital;

  double get _gainsPercentage {
    if (widget.investedCapital == 0) return 0;
    return (widget.portfolioValue - widget.investedCapital) /
        widget.investedCapital *
        100;
  }

  void _showInfoPanel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double investmentPercentage = widget.netPatrimoine > 0
        ? (widget.netWorth / widget.netPatrimoine) * 100
        : 0;

    final double yieldValue = widget.netPatrimoine > 0
        ? ((widget.patrimoineTotal - widget.netPatrimoine) /
                  widget.netPatrimoine) *
              100
        : 0;

    final Color positiveColor = isDark ? colorGreenFlash : colorGreenDark;
    final Color negativeColor = isDark ? colorOrangeLogo : colorOrangeDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ListenableBuilder(
          listenable: ThemeManager(),
          builder: (context, child) {
            final theme = Theme.of(context);
            final textStyle = theme.textTheme;
            final isDark = theme.brightness == Brightness.dark;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barre de drag
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white12
                              : Colors.black.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    Text(
                      "Détails du patrimoine",
                      style: textStyle.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section Performance
                    _buildModernInfoCard(
                      context,
                      label: "Patrimoine net constitué",
                      value: _isVisible
                          ? "${_formatAmount(widget.netPatrimoine)} €"
                          : "•••• €",
                      icon: Icons.account_balance_wallet_rounded,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.grey.shade100,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildModernInfoCard(
                            context,
                            label: "Performance globale",
                            value: _isVisible
                                ? "${yieldValue >= 0 ? '+' : ''}${yieldValue.toStringAsFixed(2)} %"
                                : "•• %",
                            icon: Icons.auto_graph_rounded,
                            color: yieldValue >= 0
                                ? positiveColor.withValues(alpha: 0.1)
                                : negativeColor.withValues(alpha: 0.1),
                            textColor: yieldValue >= 0
                                ? positiveColor
                                : negativeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // NOUVEAU : Patrimoine net estimé
                    _buildModernInfoCard(
                      context,
                      label: "Patrimoine net estimé",
                      value: _isVisible
                          ? "${_formatAmount(widget.patrimoineNetEstimated)} €"
                          : "•••• €",
                      icon: Icons.verified_user_rounded,
                      color: const Color(0xFF0D71EE).withValues(alpha: 0.1),
                      textColor: const Color(0xFF0D71EE),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      "INVESTISSEMENT",
                      style: textStyle.labelSmall?.copyWith(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildModernSmallCard(
                            context,
                            label: "Montant investi",
                            value: _isVisible
                                ? "${_formatAmount(widget.netWorth)} €"
                                : "•••• €",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildModernSmallCard(
                            context,
                            label: "Part investie",
                            value: _isVisible
                                ? "${investmentPercentage.toStringAsFixed(1)} %"
                                : "•• %",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernInfoCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    Color? textColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: textColor ?? (isDark ? Colors.white70 : Colors.black87),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: textColor ?? (isDark ? Colors.white : Colors.black),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSmallCard(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showGains = widget.hasInvestments && widget.investedCapital > 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- TOP: LABEL ---
              Text(
                "PATRIMOINE BRUT TOTAL",
                style: TextStyle(
                  color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black38,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),

              const SizedBox(height: 12),

              // --- CENTER: AMOUNT & VISIBILITY ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 40), // Spacer for centering
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showInfoPanel(context),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _isVisible
                              ? "${_formatAmount(widget.patrimoineTotal)} €"
                              : "•••••••• €",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: IconButton(
                      onPressed: () => setState(() => _isVisible = !_isVisible),
                      icon: Icon(
                        _isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: isDark ? Colors.white24 : Colors.black12,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- BOTTOM: DUAL INDICATORS ---
              if (showGains || (widget.historicalInvestmentValue != null && widget.historicalInvestmentValue! > 0))
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    // Variation Jour Badge
                    if (widget.historicalInvestmentValue != null && widget.historicalInvestmentValue! > 0)
                      _buildPremiumBadge(
                        context,
                        label: "Marchés",
                        diff: widget.portfolioValue - widget.historicalInvestmentValue!,
                        percentage: ((widget.portfolioValue - widget.historicalInvestmentValue!) / widget.historicalInvestmentValue!) * 100,
                        icon: Icons.bolt_rounded,
                      ),

                    // Gains Totaux Badge
                    if (showGains)
                      _buildPremiumBadge(
                        context,
                        label: "Gains",
                        diff: profitLoss,
                        percentage: _gainsPercentage,
                        icon: Icons.auto_graph_rounded,
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumBadge(
    BuildContext context, {
    required String label,
    required double diff,
    required double percentage,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isPositive = diff >= 0;
    final Color color = isPositive ? colorGreenFlash : const Color(0xFFFF5F5F);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                _isVisible
                    ? "${isPositive ? '+' : ''}${_formatAmount(diff)} € (${isPositive ? '+' : ''}${percentage.toStringAsFixed(2)}%)"
                    : "•••• € (••%)",
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
