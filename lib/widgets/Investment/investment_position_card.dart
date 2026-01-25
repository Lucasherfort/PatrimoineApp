import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/investment_position.dart';

class InvestmentPositionCard extends StatelessWidget {
  final InvestmentPosition position;
  final void Function(double newAveragePurchasePrice, double newQuantity)? onValueUpdated;
  final VoidCallback? onDelete;

  const InvestmentPositionCard({
    super.key,
    required this.position,
    this.onValueUpdated,
    this.onDelete,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(amount).trim();
  }

  String _formatQuantity(double quantity) {
    if (quantity % 1 == 0) {
      return quantity.toInt().toString();
    } else {
      return quantity.toStringAsFixed(4).replaceAll(RegExp(r'\.?0+$'), '');
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Supprimer la position'),
          content: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                const TextSpan(text: 'Voulez-vous vraiment supprimer la position '),
                TextSpan(
                  text: position.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' ?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                if (onDelete != null) {
                  onDelete!();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = position.latentGain >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openEditPanel(context),
        onLongPress: () => _confirmDelete(context),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête compact
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade400.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.purple.shade300.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      position.ticker,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade200,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      position.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPositive ? Colors.green.shade600 : Colors.red.shade600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${isPositive ? '+' : ''}${position.performance.toStringAsFixed(1)}%",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Valeur et gain sur une ligne
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Valeur",
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        "${_formatAmount(position.totalValue)} €",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Plus-value",
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        "${isPositive ? '+' : ''}${_formatAmount(position.latentGain)} €",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green.shade400 : Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Détails ultra-compacts
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCompactInfo("Qté", _formatQuantity(position.quantity)),
                    _buildCompactInfo("PRU", "${_formatAmount(position.pru)} €"),
                    _buildCompactInfo("Actuel", "${_formatAmount(position.currentPrice)} €"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfo(String label, String value) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void _openEditPanel(BuildContext context) {
    final pruController = TextEditingController(
      text: position.pru.toStringAsFixed(2).replaceAll('.', ','),
    );
    final quantityController = TextEditingController(
      text: _formatQuantity(position.quantity).replaceAll('.', ','),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        position.ticker,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        position.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Quantité",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.purple.shade600, width: 2),
                    ),
                    helperText: "Nombre d'actions/parts détenues",
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pruController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Prix de Revient Unitaire (PRU)",
                    suffixText: "€",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.purple.shade600, width: 2),
                    ),
                    helperText: "Prix moyen d'achat par unité",
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final pru = double.tryParse(pruController.text.replaceAll(',', '.'));
                      final quantity = double.tryParse(quantityController.text.replaceAll(',', '.'));

                      if (pru != null && quantity != null && onValueUpdated != null) {
                        onValueUpdated!(pru, quantity);
                      }
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Valider",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}