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
          title: const Text('Supprimer la position'),
          content: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                const TextSpan(text: 'Voulez-vous vraiment supprimer la position '),
                TextSpan(
                  text: position.ticker,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openEditPanel(context),
        onLongPress: () => _confirmDelete(context),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : Ticker + Nom + Performance
              Row(
                children: [
                  // Ticker
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      position.ticker,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Nom
                  Expanded(
                    child: Text(
                      position.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Badge Performance
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? Colors.green.shade400
                          : Colors.red.shade400,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 11,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          "${isPositive ? '+' : ''}${position.performance.toStringAsFixed(2)}%",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Ligne principale : Valeur + Gain
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Valeur totale
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Valeur",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        "${_formatAmount(position.totalValue)} €",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  // Plus-value
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Plus-value",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        "${isPositive ? '+' : ''}${_formatAmount(position.latentGain)} €",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPositive
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Détails compacts en ligne
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCompactInfo("Qté", _formatQuantity(position.quantity)),
                    _buildVerticalDivider(),
                    _buildCompactInfo("PRU", "${_formatAmount(position.pru)} €"),
                    _buildVerticalDivider(),
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
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.grey.shade300,
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      position.ticker,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      position.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Quantité",
                  border: OutlineInputBorder(),
                  helperText: "Nombre d'actions/parts détenues",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pruController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Prix de Revient Unitaire (PRU)",
                  suffixText: "€",
                  border: OutlineInputBorder(),
                  helperText: "Prix moyen d'achat par unité",
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final pru = double.tryParse(
                      pruController.text.replaceAll(',', '.'),
                    );
                    final quantity = double.tryParse(
                      quantityController.text.replaceAll(',', '.'),
                    );

                    if (pru != null && quantity != null && onValueUpdated != null) {
                      onValueUpdated!(pru, quantity);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Valider"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}