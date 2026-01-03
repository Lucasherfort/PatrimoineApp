import 'package:flutter/material.dart';
import '../services/patrimoine_service.dart';
import 'savings_account_card.dart';

class SavingsAccountList extends StatelessWidget {
  final List<UserSavingsAccountView> accounts;

  const SavingsAccountList({
    super.key,
    required this.accounts,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mon épargne",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...accounts.map((account) => SavingsAccountCard(account: account)),
        ],
      ),
    );
  }
}