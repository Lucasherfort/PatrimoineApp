import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatrimoineHeader extends StatefulWidget {
  final double patrimoineTotal;
  final double totalDepose;
  final double capitalOwned;
  final double patrimoineOwned;
  final bool hasInvestments; // <--- Nouveau paramètre
  final VoidCallback? onRefresh;

  const PatrimoineHeader({
    super.key,
    required this.patrimoineTotal,
    required this.totalDepose,
    required this.capitalOwned,
    required this.patrimoineOwned,
    this.hasInvestments = true, // Par défaut à true pour ne pas tout casser ailleurs
    this.onRefresh,
  });

  @override
  State<PatrimoineHeader> createState() => _PatrimoineHeaderState();
}

class _PatrimoineHeaderState extends State<PatrimoineHeader> {
  bool _isVisible = true;

  static const Color colorBlueSky = Color(0xFF67C6F2);
  static const Color colorBlueMain = Color(0xFF0D71EE);
  static const Color colorGreenFlash = Color(0xFF65E046);
  static const Color colorOrangeLogo = Color(0xFFD98006);
  static const Color colorDarkBlue = Color(0xFF060B26);

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: 2);
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [colorBlueSky, colorBlueMain],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // Si on cache les gains, on arrondit les 4 coins, sinon seulement le haut
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorBlueMain.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- Section Montant ---
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: showGains ? 24 : 32, // Un peu plus d'air si c'est le seul élément
              horizontal: 12,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildCircleAction(Icons.refresh, widget.onRefresh),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _isVisible ? "${_formatAmount(widget.patrimoineTotal)} €" : "•••••••• €",
                    key: ValueKey(_isVisible),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildCircleAction(
                    _isVisible ? Icons.visibility : Icons.visibility_off,
                        () => setState(() => _isVisible = !_isVisible),
                  ),
                ),
              ],
            ),
          ),

          // --- Section Gains conditionnelle ---
          if (showGains)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: colorDarkBlue.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _gainsColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _gains >= 0 ? Icons.trending_up : Icons.trending_down,
                          size: 16,
                          color: _gainsColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isVisible ? "${_gains >= 0 ? '+' : ''}${_formatAmount(_gains)} €" : "•••• €",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _gainsColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isVisible ? "${_gainsPercentage >= 0 ? '+' : ''}${_gainsPercentage.toStringAsFixed(2)}%" : "••%",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _gainsColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCircleAction(IconData icon, VoidCallback? onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}