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

  // --- Palette Ultra Moderne (Ardoise & Éclats néon) ---
  static const Color colorCardBg = Color(
    0xFF1E2530,
  ); // Plus sombre pour faire ressortir les éléments
  static const Color colorAccentBlue = Color(
    0xFF38BDF8,
  ); // Bleu ciel moderne / électrique
  static const Color colorGreen = Color(0xFF4ADE80); // Vert émeraude adouci
  static const Color colorRed = Color(0xFFF87171); // Rouge corail adouci
  static const Color textMain = Color(0xFFF8FAFC); // Blanc cassé haut de gamme
  static const Color textDim = Color(0xFF94A3B8); // Gris ardoise clair

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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: colorCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(
            color: trendColor,
            width: 4,
          ), // Indicateur de tendance
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openEditPanel(context),
          onLongPress: () => _confirmDelete(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // LIGNE 1 : EN-TÊTE PRINCIPAL (Identité de la position)
                // ==========================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorAccentBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          position.ticker.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: colorAccentBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            position.name,
                            style: const TextStyle(
                              color: textMain,
                              fontWeight: FontWeight.w800,
                              fontSize: 16, // Plus grand et plus visible
                              letterSpacing: 0.2,
                            ),
                            // Supprimé : maxLines et TextOverflow pour laisser le texte s'afficher entièrement
                          ),
                          const SizedBox(height: 2),
                          Text(
                            position.ticker.toUpperCase(),
                            style: const TextStyle(
                              color: colorAccentBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white10, height: 1),
                ),

                // ==========================================
                // LIGNE 2 : LES MÉTRIQUES FINANCIÈRES
                // ==========================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // BLOC COMPTE / ACHAT (Quantité & PRU)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${position.quantity.toStringAsFixed(2)} qty",
                          style: const TextStyle(
                            color: textMain,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "PRU: ${_format(position.pru)}€",
                          style: const TextStyle(color: textDim, fontSize: 11),
                        ),
                      ],
                    ),

                    // BLOC ESTIMATION LIVE (Valeur Totale, Cours Actuel, Performance)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${_format(position.totalValue)} €",
                          style: const TextStyle(
                            color: textMain,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              "Cours: ${_format(position.currentPrice)}€",
                              style: const TextStyle(
                                color: textDim,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: trendColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "${isProfit ? '▲' : '▼'} ${position.performance.toStringAsFixed(1)}%",
                                style: TextStyle(
                                  color: trendColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- MODAL DE MODIFICATION STYLE GLASSMORPHISM ---
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
          color: Color(0xFF0F172A), // Fond Slate 900 ultra premium
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Ajuster la position",
              style: TextStyle(
                color: textDim,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              position.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            _buildField(
              qtyController,
              "Quantité détenue",
              Icons.copy_all_rounded,
            ),
            const SizedBox(height: 16),
            _buildField(
              pruController,
              "Prix de revient (PRU)",
              Icons.euro_symbol_rounded,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorAccentBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                  "Enregistrer les modifications",
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
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
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: textDim, fontSize: 13),
        prefixIcon: Icon(icon, color: colorAccentBlue, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: colorAccentBlue, width: 1.5),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2530),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Supprimer la position ?",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          "Êtes-vous sûr de vouloir retirer ${position.ticker.toUpperCase()} de votre suivi ?",
          style: const TextStyle(color: textDim, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Annuler",
              style: TextStyle(color: textDim, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            child: const Text(
              "Supprimer",
              style: TextStyle(color: colorRed, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
