import 'package:flutter/material.dart';
import 'investment_card.dart';

class InvestmentList extends StatelessWidget {
  const InvestmentList({super.key});

  @override
  Widget build(BuildContext context) {
    // Données temporaires - à remplacer par tes vrais données
    final tempInvestments = [
      {'name': 'PEA Boursorama', 'type': 'Actions', 'value': 15000.0, 'performance': 8.5},
      {'name': 'Assurance Vie', 'type': 'Fonds euros', 'value': 25000.0, 'performance': 2.3},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mes placements financiers",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...tempInvestments.map((investment) => InvestmentCard(
            name: investment['name'] as String,
            type: investment['type'] as String,
            value: investment['value'] as double,
            performance: investment['performance'] as double,
          )),
        ],
      ),
    );
  }
}