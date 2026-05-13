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

  // Vert beaucoup plus sombre et saturé pour trancher sur le cyan
  Color get _gainsColor {
    if (_gains > 0) return const Color(0xFF00C853); // Vert émeraude ultra-flash
    if (_gains < 0) return Colors.redAccent.shade700;
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.cyan.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- Partie Haute : Montant Centré ---
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 20, 8, 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Bouton Refresh à gauche
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                    onPressed: widget.onRefresh,
                  ),
                ),
                // MONTANT CENTRAL
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
                      letterSpacing: -1,
                    ),
                  ),
                ),
                // Bouton Visibilité à droite
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      _isVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isVisible = !_isVisible),
                  ),
                ),
              ],
            ),
          ),

          // --- Partie Basse : Gains avec fond contrasté ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9), // Fond blanc quasi-opaque pour que le vert ressorte
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Centré aussi
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
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 15,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(width: 12),
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