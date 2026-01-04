import 'package:flutter/material.dart';

class InvestmentSummaryHeader extends StatelessWidget {
  final double cashBalance;
  final double positionsValue;
  final double totalProfitLoss;
  final double cumulativeDeposits;

  const InvestmentSummaryHeader({
    super.key,
    required this.cashBalance,
    required this.positionsValue,
    required this.totalProfitLoss,
    required this.cumulativeDeposits,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfo("Espèces", cashBalance),
            _buildInfo("Titres", positionsValue),
            _buildInfo("Total +/-", totalProfitLoss, highlight: true),
            _buildInfo("Versements", cumulativeDeposits),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(
      String label,
      double value, {
        bool highlight = false,
      }) {
    final color = highlight
        ? (value >= 0 ? Colors.green : Colors.red)
        : Colors.black;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          "${value.toStringAsFixed(2)} €",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}