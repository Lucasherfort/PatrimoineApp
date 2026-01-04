import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/investment_service.dart';
import '../models/investment_position.dart';

class InvestmentSummaryHeader extends StatelessWidget {
  final UserInvestmentAccountView account;
  final List<InvestmentPosition> positions;

  const InvestmentSummaryHeader({
    super.key,
    required this.account,
    required this.positions,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(amount).trim();
  }

  // Calcule la valeur totale des positions (titres)
  double get positionsValue {
    return positions.fold(0.0, (sum, position) => sum + position.totalValue);
  }

  // Calcule la valeur totale (espèces + titres)
  double get totalValue => account.cashBalance + positionsValue;

  // Calcule les plus-values totales
  double get totalProfitLoss {
    return positions.fold(0.0, (sum, position) => sum + position.latentGain);
  }

  // Calcule les versements cumulés (valeur actuelle - plus-values)
  double get cumulativeDeposits => totalValue - totalProfitLoss;

  @override
  Widget build(BuildContext context) {
    final isProfit = totalProfitLoss >= 0;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade700,
            Colors.indigo.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.shade200.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Valeur totale en grand
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Valeur totale",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_formatAmount(totalValue)} €",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                // Badge de performance
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isProfit
                        ? Colors.green.shade400
                        : Colors.red.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isProfit ? Icons.trending_up : Icons.trending_down,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${isProfit ? '+' : ''}${_formatAmount(totalProfitLoss)} €",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Séparateur
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            // Détails en grille
            Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    icon: Icons.account_balance_wallet,
                    label: "Espèces",
                    value: "${_formatAmount(account.cashBalance)} €",
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildMetric(
                    icon: Icons.trending_up,
                    label: "Titres",
                    value: "${_formatAmount(positionsValue)} €",
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildMetric(
                    icon: Icons.savings,
                    label: "Versements",
                    value: "${_formatAmount(cumulativeDeposits)} €",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}