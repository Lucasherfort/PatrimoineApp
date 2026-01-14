import 'package:flutter/material.dart';
import '../../services/liquidity_account_service.dart';
import '../../models/liquidity/user_liquidity_account_view.dart';
import 'liquidity_account_card.dart';

class LiquidityAccountList extends StatefulWidget {
  final VoidCallback onAccountUpdated;

  const LiquidityAccountList({
    super.key,
    required this.onAccountUpdated,
  });

  @override
  State<LiquidityAccountList> createState() => _LiquidityAccountListState();
}

class _LiquidityAccountListState extends State<LiquidityAccountList> {
  final LiquidityAccountService _service = LiquidityAccountService();
  late Future<List<UserLiquidityAccountView>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() {
    _accountsFuture = _service.getUserLiquidityAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserLiquidityAccountView>>(
      future: _accountsFuture,
      builder: (context, snapshot) {
        // 👇 Retirer le loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(); // Rien pendant le chargement
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Erreur de chargement des liquidités',
              style: TextStyle(color: Colors.red.shade700),
            ),
          );
        }

        final accounts = snapshot.data ?? [];

        if (accounts.isEmpty) {
          return const SizedBox(); // pas d'affichage si vide
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Liquidités",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...accounts.map(
                  (account) => LiquidityAccountCard(
                account: account,
                onValueUpdated: (newValue) async {
                  await _service.updateAmount(
                      accountId: account.id, amount: newValue);
                  widget.onAccountUpdated();
                  setState(_loadAccounts);
                },
                onDeleted: () {
                  widget.onAccountUpdated();
                  setState(_loadAccounts);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}