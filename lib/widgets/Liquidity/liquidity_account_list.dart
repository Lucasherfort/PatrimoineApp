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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Erreur de chargement des liquidités',
              style: TextStyle(color: Colors.red.shade400),
            ),
          );
        }

        final accounts = snapshot.data ?? [];

        // 🔹 Trier par amount décroissant
        accounts.sort((a, b) => b.amount.compareTo(a.amount));

        if (accounts.isEmpty) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade400.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: Colors.green.shade300,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Liquidités",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${accounts.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...accounts.map(
                  (account) => LiquidityAccountCard(
                account: account,
                onValueUpdated: (newValue) async {
                  await _service.updateAmount(
                    accountId: account.id,
                    amount: newValue,
                  );
                  widget.onAccountUpdated();
                  setState(_loadAccounts);
                },
                onDeleted: () {
                  widget.onAccountUpdated();
                  setState(_loadAccounts);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}