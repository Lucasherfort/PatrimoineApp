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

  // =========================
  // Calculs
  // =========================

  double get _gains => widget.patrimoineTotal - widget.totalDepose;

  double get _gainsPercentage {
    if (widget.totalDepose == 0) return 0;
    return (_gains / widget.totalDepose) * 100;
  }

  // Patrimoine net = sans intérêts / avantages
  double get _patrimoineNet => widget.totalDepose;

  // % des intérêts dans le patrimoine total
  double get _interetsPourcentagePatrimoine {
    if (widget.patrimoineTotal == 0) return 0;
    return (_gains / widget.patrimoineTotal) * 100;
  }

  Color get _gainsColor {
    if (_gains > 0) return colorGreenFlash;
    if (_gains < 0) return colorOrangeLogo;
    return Colors.white70;
  }

  // =========================
  // Bottom Sheet
  // =========================

  void _showPatrimoineDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barre du haut
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Détail du patrimoine",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 28),

              _buildInfoRow(
                "Patrimoine total",
                "${_formatAmount(widget.patrimoineTotal)} €",
              ),

              const SizedBox(height: 18),

              _buildInfoRow(
                "Patrimoine net",
                "${_formatAmount(_patrimoineNet)} €",
              ),

              const SizedBox(height: 18),

              _buildInfoRow(
                "Intérêts / avantages",
                "${_gains >= 0 ? '+' : ''}${_formatAmount(_gains)} €",
                valueColor: _gainsColor,
              ),

              const SizedBox(height: 18),

              _buildInfoRow(
                "% des intérêts",
                "${_interetsPourcentagePatrimoine.toStringAsFixed(2)} %",
                valueColor: _gainsColor,
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
      String label,
      String value, {
        Color valueColor = Colors.white,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showGains =
        widget.hasInvestments && widget.totalDepose > 0;

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
                    icon: Icon(
                      Icons.visibility_outlined,
                      size: 22,
                    ),
                  ),
                ),

                // Montant centré et cliquable
                Expanded(
                  child: GestureDetector(
                    onTap: _showPatrimoineDetails,
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
                  _gains >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
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