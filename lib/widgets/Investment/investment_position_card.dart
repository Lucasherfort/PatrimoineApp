import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/investment_position.dart';

class InvestmentPositionCard extends StatelessWidget {
  final InvestmentPosition position;
  final void Function(double newPru, double newQty)? onValueUpdated;
  final VoidCallback? onDelete;

  const InvestmentPositionCard({
    super.key,
    required this.position,
    this.onValueUpdated,
    this.onDelete,
  });

  // --- Palette de couleurs pour fond clair ---
  static const Color colorGreen = Color(
    0xFF1B823D,
  ); // Vert plus dense pour le contraste
  static const Color colorRed = Color(0xFFD32F2F); // Rouge plus dense
  static const Color colorBlue = Color(0xFF0D71EE);
  static const Color textDark = Color(
    0xFF0F172A,
  ); // Bleu nuit très profond pour les textes

  String _format(double val) {
    return NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '',
      decimalDigits: 2,
    ).format(val).trim();
  }

  @override
  Widget build(BuildContext context) {
    final isProfit = position.latentGain >= 0;
    final trendColor = isProfit ? colorGreen : colorRed;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        // Fond blanc lumineux (92% d'opacité pour garder un léger effet de profondeur)
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openEditPanel(context),
            onLongPress: () => _confirmDelete(context),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // --- LIGNE 1 : TITRE & PERFORMANCE ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              position.ticker.toUpperCase(),
                              style: const TextStyle(
                                color: colorBlue,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              position.name,
                              style: const TextStyle(
                                color: textDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge de performance
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: trendColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${isProfit ? '+' : ''}${_format(position.latentGain)} €",
                              style: TextStyle(
                                color: trendColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "${isProfit ? '+' : ''}${position.performance.toStringAsFixed(2)}%",
                              style: TextStyle(
                                color: trendColor.withValues(alpha: 0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: Colors.black12, height: 1),
                  ),

                  // --- LIGNE 2 : GRILLE DE DONNÉES ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDataColumn(
                        "VALEUR",
                        "${_format(position.totalValue)} €",
                        isBold: true,
                      ),
                      _buildDataColumn(
                        "QTÉ",
                        position.quantity.toStringAsFixed(2),
                      ),
                      _buildDataColumn("PRU", "${_format(position.pru)} €"),
                      _buildDataColumn(
                        "COURS",
                        "${_format(position.currentPrice)} €",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataColumn(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textDark.withValues(alpha: 0.4),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isBold ? textDark : textDark.withValues(alpha: 0.85),
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // --- MODAL DE MODIFICATION (DARK POUR LE CONTRASTE) ---
  void _openEditPanel(BuildContext context) {
    final pruController = TextEditingController(
      text: position.pru.toString().replaceAll('.', ','),
    );
    final qtyController = TextEditingController(
      text: position.quantity.toString().replaceAll('.', ','),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(
            0xFF0F172A,
          ), // On garde la modal sombre pour le style "Premium"
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              position.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildField(
              qtyController,
              "Quantité détenue",
              Icons.layers_outlined,
            ),
            const SizedBox(height: 16),
            _buildField(
              pruController,
              "Prix de revient (PRU)",
              Icons.euro_symbol_rounded,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  final p = double.tryParse(
                    pruController.text.replaceAll(',', '.'),
                  );
                  final q = double.tryParse(
                    qtyController.text.replaceAll(',', '.'),
                  );
                  if (p != null && q != null) onValueUpdated?.call(p, q);
                  Navigator.pop(context);
                },
                child: const Text(
                  "METTRE À JOUR",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: colorBlue, size: 22),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Supprimer la position",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Voulez-vous retirer ${position.ticker} de votre portefeuille ?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Annuler",
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            child: const Text(
              "Supprimer",
              style: TextStyle(color: colorRed, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
