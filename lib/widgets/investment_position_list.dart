import 'package:flutter/material.dart';
import '../models/investment_position.dart';
import 'investment_position_card.dart';

class InvestmentPositionList extends StatelessWidget {
  final List<InvestmentPosition> positions;
  final bool isLoading;

  const InvestmentPositionList({
    super.key,
    required this.positions,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (positions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune position dans ce compte',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: positions.length,
      itemBuilder: (context, index) {
        return InvestmentPositionCard(position: positions[index]);
      },
    );
  }
}