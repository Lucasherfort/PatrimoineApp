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
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    }

    if (positions.isEmpty) {
      return Center(
        child: Opacity(
          opacity: 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucune position active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ajoutez votre premier actif',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        100,
      ), // Espace pour le scroll
      itemCount: positions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final position = positions[index];
        return InvestmentPositionCard(
          position: position,
          onValueUpdated: (newPru, newQuantity) =>
              _updatePosition(context, position, newPru, newQuantity),
          onDelete: () => _deletePosition(context, position),
        );
      },
    );
  }

  // --- Logique de mise à jour (simplifiée pour la lisibilité) ---
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

      if (!context.mounted) return;

      if (hasChanged) {
        onPositionUpdated?.call();
      }
    } catch (e) {
      if (!context.mounted) return;

      _showError(context, e.toString());
    }
  }

  Future<void> _deletePosition(
    BuildContext context,
    InvestmentPosition position,
  ) async {
    try {
      await positionService.deletePosition(position.id);

      if (!context.mounted) return;

      onPositionUpdated?.call();
    } catch (e) {
      if (!context.mounted) return;

      _showError(context, e.toString());
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }
}
