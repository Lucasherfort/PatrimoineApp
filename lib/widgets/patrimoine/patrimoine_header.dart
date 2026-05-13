import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatrimoineHeader extends StatefulWidget {
  final double patrimoineTotal;
  final double totalDepose;
  final double capitalOwned;
  final double patrimoineOwned;
  final bool hasInvestments;
  final VoidCallback? onRefresh;

  const PatrimoineHeader({
    super.key,
    required this.patrimoineTotal,
    required this.totalDepose,
    required this.capitalOwned,
    required this.patrimoineOwned,
    this.hasInvestments = true,
    this.onRefresh,
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

  double get _gains => widget.patrimoineTotal - widget.totalDepose;

  double get _gainsPercentage {
    if (widget.totalDepose == 0) return 0;
    return (_gains / widget.totalDepose) * 100;
  }

  Color get _gainsColor {
    if (_gains > 0) return colorGreenFlash;
    if (_gains < 0) return colorOrangeLogo;
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    final bool showGains = widget.hasInvestments && widget.totalDepose > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, bottom: 20), // Plus besoin de margin/decoration
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Libellé discret au-dessus
          Text(
            "PATRIMOINE TOTAL",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),

          // --- Ligne 1 : Actions + Montant ---
          Row(
            children: [
              const SizedBox(width: 16),
              _buildCircleAction(Icons.refresh, widget.onRefresh),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _isVisible
                          ? "${_formatAmount(widget.patrimoineTotal)} €"
                          : "•••••••• €",
                      key: ValueKey(_isVisible),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 36, // Légèrement augmenté car plus de contrainte de boîte
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                ),
              ),
              _buildCircleAction(
                _isVisible ? Icons.visibility : Icons.visibility_off,
                    () => setState(() => _isVisible = !_isVisible),
              ),
              const SizedBox(width: 16),
            ],
          ),

          // --- Ligne 2 : Gains (Sans capsule noire, juste le texte) ---
          if (showGains) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _gains >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: _gainsColor,
                ),
                const SizedBox(width: 6),
                Text(
                  _isVisible
                      ? "${_gains >= 0 ? '+' : ''}${_formatAmount(_gains)} € (${_gainsPercentage >= 0 ? '+' : ''}${_gainsPercentage.toStringAsFixed(2)}%)"
                      : "•••• €",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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

  Widget _buildCircleAction(IconData icon, VoidCallback? onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 20),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}