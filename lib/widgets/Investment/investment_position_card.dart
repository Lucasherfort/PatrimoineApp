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

  // --- Palette "Slate Modern" (Équilibre entre visibilité et thème sombre) ---
  static const Color colorCardBg = Color(0xFF2D3748); // Gris-bleu acier (plus clair)
  static const Color colorAccentBlue = Color(0xFF3182CE);
  static const Color colorGreen = Color(0xFF48BB78);
  static const Color colorRed = Color(0xFFF56565);
  static const Color textMain = Colors.white;
  static const Color textDim = Color(0xFFA0AEC0);

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
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: colorCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openEditPanel(context),
          onLongPress: () => _confirmDelete(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // 1. INDICATEUR VISUEL (Ticker)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      position.ticker.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: colorAccentBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. NOM ET TICKER
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        position.name,
                        style: const TextStyle(
                          color: textMain,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        position.ticker.toUpperCase(),
                        style: const TextStyle(
                          color: textDim,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. PRU & QUANTITÉ (Discret)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${_format(position.pru)}€",
                        style: const TextStyle(color: textMain, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        "${position.quantity.toStringAsFixed(2)} qty",
                        style: const TextStyle(color: textDim, fontSize: 10),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // 4. VALEUR TOTALE ET PERFORMANCE
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${_format(position.totalValue)} €",
                        style: const TextStyle(
                          color: textMain,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        "${isProfit ? '+' : ''}${position.performance.toStringAsFixed(2)}%",
                        style: TextStyle(
                          color: trendColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- MODAL DE MODIFICATION ---
  void _openEditPanel(BuildContext context) {
    final pruController = TextEditingController(text: position.pru.toString().replaceAll('.', ','));
    final qtyController = TextEditingController(text: position.quantity.toString().replaceAll('.', ','));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A202C), // Fond modal très sombre
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
            left: 24, right: 24, top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(position.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildField(qtyController, "Quantité détenue", Icons.layers_outlined),
            const SizedBox(height: 16),
            _buildField(pruController, "Prix de revient (PRU)", Icons.euro_symbol_rounded),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorAccentBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final p = double.tryParse(pruController.text.replaceAll(',', '.'));
                  final q = double.tryParse(qtyController.text.replaceAll(',', '.'));
                  if (p != null && q != null) onValueUpdated?.call(p, q);
                  Navigator.pop(context);
                },
                child: const Text("METTRE À JOUR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      style: const TextStyle(color: Colors.white),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: textDim),
        prefixIcon: Icon(icon, color: colorAccentBlue),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D3748),
        title: const Text("Supprimer ?", style: TextStyle(color: Colors.white)),
        content: Text("Retirer ${position.ticker} ?", style: const TextStyle(color: textDim)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Non", style: TextStyle(color: textDim))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            child: const Text("Oui, supprimer", style: TextStyle(color: colorRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}