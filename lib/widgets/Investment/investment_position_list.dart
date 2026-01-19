import 'package:flutter/material.dart';
import '../../models/investment_position.dart';
import '../../services/position_service.dart';
import 'investment_position_card.dart';

class InvestmentPositionList extends StatelessWidget {
  final List<InvestmentPosition> positions;
  final bool isLoading;
  final PositionService positionService;
  final VoidCallback? onPositionUpdated;

  const InvestmentPositionList({
    super.key,
    required this.positions,
    required this.isLoading,
    required this.positionService,
    this.onPositionUpdated,
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
        return InvestmentPositionCard(
          position: positions[index],
          onValueUpdated: (newPru, newQuantity) {
            _updatePosition(
              context,
              positions[index],
              newPru,
              newQuantity,
            );
          },
          onDelete: () {
            _deletePosition(context, positions[index]);
          },
        );
      },
    );
  }

  Future<void> _updatePosition(
      BuildContext context,
      InvestmentPosition position,
      double newPru,
      double newQuantity,
      ) async {
    try {
      final hasChanged = await positionService.updatePosition(
        positionId: position.id,
        pru: newPru,
        quantity: newQuantity,
      );

      if (hasChanged && onPositionUpdated != null) {
        onPositionUpdated!();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                hasChanged
                    ? 'Position ${position.ticker} mise à jour'
                    : 'Position ${position.ticker} : aucun changement'
            ),
            backgroundColor: hasChanged ? Colors.green : Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour : $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ✅ Méthode pour supprimer une position
  Future<void> _deletePosition(
      BuildContext context,
      InvestmentPosition position,
      ) async {
    try {
      await positionService.deletePosition(position.id);

      if (onPositionUpdated != null) {
        onPositionUpdated!();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Position ${position.ticker} supprimée'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression : $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}