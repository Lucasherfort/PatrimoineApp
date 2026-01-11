import 'package:flutter/material.dart';
import '../../services/savings_account_service.dart';
import '../../models/savings/user_savings_account_view.dart';
import 'savings_account_card.dart';

class SavingsAccountList extends StatefulWidget {
  final VoidCallback onAccountUpdated;

  const SavingsAccountList({
    super.key,
    required this.onAccountUpdated,
  });

  @override
  State<SavingsAccountList> createState() => _SavingsAccountListState();
}

class _SavingsAccountListState extends State<SavingsAccountList> {
  final SavingsAccountService _service = SavingsAccountService();
  late Future<List<UserSavingsAccountView>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() {
    _accountsFuture = _service.getUserSavingsAccounts();
  }

  Future<void> _updateAccount(
      int accountId, double newBalance, double newInterest) async {
    await _service.updateSavingsAccount(
      accountId: accountId,
      balance: newBalance,
      interestAccrued: newInterest,
    );
    widget.onAccountUpdated();
    setState(_loadAccounts);
  }

  Future<void> _deleteAccount(int accountId) async {
    await _service.deleteSavingsAccount(accountId);
    widget.onAccountUpdated();
    setState(_loadAccounts);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserSavingsAccountView>>(
      future: _accountsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Erreur de chargement des comptes épargne',
              style: TextStyle(color: Colors.red.shade700),
            ),
          );
        }

        final accounts = snapshot.data ?? [];

        if (accounts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Épargne",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...accounts.map(
                  (account) => SavingsAccountCard(
                account: account,
                onValueUpdated: (newBalance, newInterest) =>
                    _updateAccount(account.id, newBalance, newInterest),
                onDeleted: () => _deleteAccount(account.id),
              ),
            ),
          ],
        );
      },
    );
  }
}
