import 'package:flutter/material.dart';
import '../../services/advantage_service.dart';
import '../../models/advantage/user_advantage_account_view.dart';
import 'advantage_account_card.dart';

class AdvantageAccountList extends StatefulWidget {
  final VoidCallback onAccountUpdated;

  const AdvantageAccountList({super.key, required this.onAccountUpdated});

  @override
  State<AdvantageAccountList> createState() => _AdvantageAccountListState();
}

class _AdvantageAccountListState extends State<AdvantageAccountList> {
  final AdvantageService _service = AdvantageService();
  late Future<List<UserAdvantageAccountView>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() {
    _accountsFuture = _service.getUserAdvantageAccounts();
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
    return FutureBuilder<List<UserAdvantageAccountView>>(
      future: _accountsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Erreur de chargement des avantages',
              style: TextStyle(color: Colors.red.shade400),
            ),
          );
        }

        final accounts = snapshot.data ?? [];

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
                      color: Colors.orange.shade400.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.card_giftcard,
                      color: Colors.orange.shade300,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Avantages",
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
                        color: Colors.orange.shade400.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade400.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${_formatAmount(accounts.fold<double>(0, (sum, a) => sum + a.value))} €',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade300,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ...accounts.map(
              (account) => AdvantageAccountCard(
                account: account,
                onValueUpdated: (newValue) async {
                  await _service.updateValue(
                    accountId: account.id,
                    value: newValue,
                  );
                  widget.onAccountUpdated();
                  setState(_loadAccounts);
                },
                onDeleted: () async {
                  await _service.deleteAccount(account.id);
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
