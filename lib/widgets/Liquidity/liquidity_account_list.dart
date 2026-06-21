import 'package:flutter/material.dart';
import '../../services/liquidity_service.dart';
import '../../models/liquidity/user_liquidity_account_view.dart';
import 'liquidity_account_card.dart';

class LiquidityAccountList extends StatefulWidget {
  final VoidCallback onAccountUpdated;

  const LiquidityAccountList({super.key, required this.onAccountUpdated});

  @override
  State<LiquidityAccountList> createState() => _LiquidityAccountListState();
}

class _LiquidityAccountListState extends State<LiquidityAccountList> {
  final LiquidityService _service = LiquidityService();
  late Future<List<UserLiquidityAccountView>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() {
    _accountsFuture = _service.getUserLiquidityAccounts();
  }

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}\u00A0',
    );
    return '$intPart,${parts[1]}';
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
                      Icons.water_drop_rounded,
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
                  if (accounts.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade900.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.shade400.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${_formatAmount(accounts.fold<double>(0, (sum, a) => sum + a.amount))} €',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade300,
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
