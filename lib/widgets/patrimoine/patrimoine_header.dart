import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatrimoineHeader extends StatefulWidget {
  final double patrimoineTotal;
  final double patrimoineBrut;
  final double investedCapital;
  final double portfolioValue;
  final double netWorth;
  final double netPatrimoine;
  final bool hasInvestments;

  const PatrimoineHeader({
    super.key,
    required this.patrimoineTotal,
    required this.patrimoineBrut,
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
    final double investmentPercentage = widget.patrimoineTotal > 0
        ? (widget.netWorth / widget.netPatrimoine) * 100
        : 0;

    final double yieldValue = widget.netPatrimoine > 0
        ? ((widget.patrimoineBrut - widget.netPatrimoine) /
                widget.netPatrimoine) *
            100
        : 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barre de drag
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _buildInfoRow(
                  "Patrimoine net (total versé)",
                  _isVisible
                      ? "${_formatAmount(widget.netPatrimoine)} €"
                      : "•••• €",
                ),
                const Divider(color: Colors.black12, height: 32),
                _buildInfoRow(
                  "Patrimoine brut (hors avantages)",
                  _isVisible
                      ? "${_formatAmount(widget.patrimoineBrut)} €"
                      : "•••• €",
                ),
                const Divider(color: Colors.black12, height: 32),
                _buildInfoRow(
                  "Rendement global",
                  _isVisible
                      ? "${yieldValue >= 0 ? '+' : ''}${yieldValue.toStringAsFixed(2)} %"
                      : "•• %",
                  valueColor: yieldValue >= 0 ? colorGreenFlash : colorOrangeLogo,
                ),
                const Divider(color: Colors.black12, height: 32),
                _buildInfoRow(
                  "Montant net investi",
                  _isVisible ? "${_formatAmount(widget.netWorth)} €" : "•••• €",
                ),
                const Divider(color: Colors.black12, height: 32),
                _buildInfoRow(
                  "Pourcentage d'investissement",
                  _isVisible
                      ? "${investmentPercentage.toStringAsFixed(2)} %"
                      : "•• %",
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
