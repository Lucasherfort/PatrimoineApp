import 'package:flutter/material.dart';

class CashAccountList extends StatelessWidget {
  final int userId;
  final VoidCallback onAccountUpdated;

  const CashAccountList({
    super.key,
    required this.userId,
    required this.onAccountUpdated,
  });

  @override
  Widget build(BuildContext context) {
    // Remplace par la vraie liste ou placeholder
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text('Liste des comptes espèces pour user $userId'),
    );
  }
}