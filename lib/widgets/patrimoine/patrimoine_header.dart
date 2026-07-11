import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatrimoineHeader extends StatefulWidget {
  final double patrimoineTotal;
  final double investedCapital;
  final double portfolioValue;
  final double netWorth;
  final double netPatrimoine;
  final bool hasInvestments;

  const PatrimoineHeader({
    super.key,
    required this.patrimoineTotal,
    required this.investedCapital,
    required this.portfolioValue,
    required this.netWorth,
    required this.netPatrimoine,
    this.hasInvestments = true,
  });

  @override
  State<PatrimoineHeader> createState() => _PatrimoineHeaderState();
}

class _PatrimoineHeaderState extends State<PatrimoineHeader> {
  bool _isVisible = true;

  static const Color colorGreenFlash = Color(0xFF65E046);
  static const Color colorOrangeLogo = Color(0xFFD98006);

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

  Color get _gainsColor {
    if (_gainsPercentage > 0) return colorGreenFlash;
    if (_gainsPercentage < 0) return colorOrangeLogo;
    return Colors.white70;
  }

  void _showInfoPanel(BuildContext context) {
    final double investmentPercentage = widget.netPatrimoine > 0
        ? (widget.netWorth / widget.netPatrimoine) * 100
        : 0;

    final double yieldValue = widget.netPatrimoine > 0
        ? ((widget.patrimoineTotal - widget.netPatrimoine) /
                  widget.netPatrimoine) *
              100
        : 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const Text(
                  "Détails du patrimoine",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Section Performance
                _buildModernInfoCard(
                  label: "Patrimoine net (versé)",
                  value: _isVisible
                      ? "${_formatAmount(widget.netPatrimoine)} €"
                      : "•••• €",
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.grey.shade100,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildModernInfoCard(
                        label: "Rendement global",
                        value: _isVisible
                            ? "${yieldValue >= 0 ? '+' : ''}${yieldValue.toStringAsFixed(2)} %"
                            : "•• %",
                        icon: Icons.auto_graph_rounded,
                        color: yieldValue >= 0
                            ? colorGreenFlash.withValues(alpha: 0.1)
                            : colorOrangeLogo.withValues(alpha: 0.1),
                        textColor: yieldValue >= 0
                            ? colorGreenFlash
                            : colorOrangeLogo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text(
                  "INVESTISSEMENT",
                  style: TextStyle(
                    color: Colors.black38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildModernSmallCard(
                        label: "Montant investi",
                        value: _isVisible
                            ? "${_formatAmount(widget.netWorth)} €"
                            : "•••• €",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernSmallCard(
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
  }

  Widget _buildModernInfoCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor ?? Colors.black87, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: textColor ?? Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSmallCard({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black38,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // =========================
          // Label
          // =========================
          Text(
            "PATRIMOINE TOTAL",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),

          const SizedBox(height: 10),

          // =========================
          // Montant principal
          // =========================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Placeholder invisible pour garder le centrage
                const Opacity(
                  opacity: 0,
                  child: IconButton(
                    onPressed: null,
                    icon: Icon(Icons.visibility_outlined, size: 22),
                  ),
                ),

                // Montant centré et cliquable
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showInfoPanel(context),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _isVisible
                              ? "${_formatAmount(widget.patrimoineTotal)} €"
                              : "•••••••• €",
                          key: ValueKey(_isVisible),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bouton visibilité
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isVisible = !_isVisible;
                    });
                  },
                  icon: Icon(
                    _isVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),

          // =========================
          // Gains
          // =========================
          if (showGains) ...[
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  profitLoss >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: _gainsColor,
                ),

                const SizedBox(width: 6),

                Text(
                  _isVisible
                      ? "${profitLoss >= 0 ? '+' : ''}${_formatAmount(profitLoss)} € (${_gainsPercentage >= 0 ? '+' : ''}${_gainsPercentage.toStringAsFixed(2)}%)"
                      : "•••• €",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _gainsColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
