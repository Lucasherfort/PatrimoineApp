import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatrimoineHeader extends StatefulWidget {
  final double patrimoineTotal;
  final double totalDepose;
  final double capitalOwned;
  final double patrimoineOwned;
  final bool hasInvestments;

  const PatrimoineHeader({
    super.key,
    required this.patrimoineTotal,
    required this.totalDepose,
    required this.capitalOwned,
    required this.patrimoineOwned,
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
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Libellé discret
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

          // --- Zone Montant (Correction du centrage et superposition) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Placeholder invisible pour équilibrer le centrage
                const Opacity(
                  opacity: 0,
                  child: IconButton(
                    onPressed: null,
                    icon: Icon(Icons.visibility_outlined, size: 22),
                  ),
                ),

                // 2. Montant centré
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: FittedBox(
                      fit: BoxFit
                          .scaleDown, // Empêche le chevauchement si le chiffre est long
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

                // 3. Bouton visibilité réel
                IconButton(
                  onPressed: () => setState(() => _isVisible = !_isVisible),
                  icon: Icon(
                    _isVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),

          // --- Gains ---
          if (showGains) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _gains >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: _gainsColor,
                ),
                const SizedBox(width: 6),
                Text(
                  _isVisible
                      ? "${_gains >= 0 ? '+' : ''}${_formatAmount(_gains)} € (${_gainsPercentage >= 0 ? '+' : ''}${_gainsPercentage.toStringAsFixed(2)}%)"
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
