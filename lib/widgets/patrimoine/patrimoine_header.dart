import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatrimoineHeader extends StatefulWidget {
  final double patrimoineTotal;
  final double totalDepose;
  final double capitalOwned;
  final double patrimoineOwned;
  final VoidCallback? onRefresh;

  const PatrimoineHeader({
    super.key,
    required this.patrimoineTotal,
    required this.totalDepose,
    required this.capitalOwned,
    required this.patrimoineOwned,
    this.onRefresh,
  });

  @override
  State<PatrimoineHeader> createState() => _PatrimoineHeaderState();
}

class _PatrimoineHeaderState extends State<PatrimoineHeader> {
  bool _isVisible = true;

  // Tes couleurs de logo
  static const Color colorBlueSky = Color(0xFF67C6F2);
  static const Color colorBlueMain = Color(0xFF0D71EE);
  static const Color colorGreenLogo = Color(0xFF2DB23A);
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
    if (_gains > 0) return colorGreenLogo;
    if (_gains < 0) return colorOrangeLogo;
    return Colors.grey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // Utilisation de ton dégradé de logo
        gradient: const LinearGradient(
          colors: [colorBlueSky, colorBlueMain],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorBlueMain.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- Montant Centré ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
                    onPressed: widget.onRefresh,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _isVisible
                        ? "${_formatAmount(widget.patrimoineTotal)} €"
                        : "•••••••• €",
                    key: ValueKey(_isVisible),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      _isVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => setState(() => _isVisible = !_isVisible),
                  ),
                ),
              ],
            ),
          ),

          // --- Barre de Gains (Fond blanc pur pour faire ressortir ton vert) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _gains >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 18,
                  color: _gainsColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _isVisible ? "${_gains >= 0 ? '+' : ''}${_formatAmount(_gains)} €" : "•••• €",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _gainsColor,
                  ),
                ),
                const SizedBox(width: 15),
                Container(width: 1, height: 15, color: Colors.grey.shade200),
                const SizedBox(width: 15),
                Text(
                  _isVisible ? "${_gainsPercentage >= 0 ? '+' : ''}${_gainsPercentage.toStringAsFixed(2)}%" : "••%",
                  style: TextStyle(
                    fontSize: 16,
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
}