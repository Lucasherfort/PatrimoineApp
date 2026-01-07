import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/investment_position.dart';

class InvestmentPositionCard extends StatelessWidget {
  final InvestmentPosition position;

  const InvestmentPositionCard({
    super.key,
    required this.position,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(amount).trim();
  }

  // ✅ Nouvelle méthode pour formater la quantité
  String _formatQuantity(double quantity) {
    if (quantity % 1 == 0) {
      // Si c'est un entier (273.0 → 273)
      return quantity.toInt().toString();
    } else {
      // Si c'est un décimal (123.456 → 123.456)
      return quantity.toStringAsFixed(4).replaceAll(RegExp(r'\.?0+$'), '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPrice = position.currentPrice != null;
    final isPositive = position.latentGain >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec ticker et nom
            Row(
              children: [
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
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        position.name ?? position.ticker,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        position.supportType,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // Infos compactes en grille 2x2
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    "Quantité",
                    _formatQuantity(position.quantity), // ✅ Utilise la nouvelle méthode
                    Colors.black87,
                  ),
                ),
                Expanded(
                  child: _buildInfoTile(
                    "PRU",
                    "${_formatAmount(position.averagePurchasePrice)} €",
                    Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    "Prix actuel",
                    hasPrice ? "${_formatAmount(position.currentPrice!)} €" : "N/A",
                    hasPrice ? Colors.blue.shade700 : Colors.grey,
                  ),
                ),
                Expanded(
                  child: _buildInfoTile(
                    "Valeur",
                    "${_formatAmount(position.totalValue)} €",
                    Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Plus-value et performance en ligne
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 16,
                        color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${isPositive ? '+' : ''}${_formatAmount(position.latentGain)} €",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPositive ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${isPositive ? '+' : ''}${position.performance.toStringAsFixed(2)}%",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}