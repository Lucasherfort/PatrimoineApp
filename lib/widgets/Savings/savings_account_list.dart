import 'package:flutter/material.dart';
import '../../models/savings/user_savings_account_view.dart';
import '../../services/savings_account_service.dart';
import 'savings_account_card.dart';

class SavingsAccountList extends StatefulWidget {
  final VoidCallback onAccountUpdated;

  const SavingsAccountList({super.key, required this.onAccountUpdated});

  @override
  State<SavingsAccountList> createState() => _SavingsAccountListState();
}

class _SavingsAccountListState extends State<SavingsAccountList> {
  final SavingsAccountService _service = SavingsAccountService();
  late Future<List<UserSavingsAccountView>> _accountsFuture;
  List<UserSavingsAccountView> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() {
    _accountsFuture = _service.getUserSavingsAccounts();
    _accountsFuture.then((accounts) {
      accounts.sort((a, b) => (b.principal + b.interest)
          .compareTo(a.principal + a.interest));

      setState(() {
        _accounts = accounts;
      });
    });
  }

  Future<void> _deleteAccount(int accountId) async {
    await _service.deleteSavingsAccount(accountId);
    _accounts.removeWhere((a) => a.id == accountId);
    setState(() {});
    widget.onAccountUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserSavingsAccountView>>(
      future: _accountsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Erreur de chargement des comptes épargne',
              style: TextStyle(color: Colors.red.shade400),
            ),
          );
        }

        if (_accounts.isEmpty) {
          return const SizedBox.shrink();
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
                      color: Colors.blue.shade400.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.savings_rounded,
                      color: Colors.blue.shade300,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Épargne",
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
                      color: Colors.blue.shade400.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.shade400.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${_accounts.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ..._accounts.map((account) => SavingsAccountCard(
              account: account,
              onValueUpdated: (updatedAccount) {
                final index =
                _accounts.indexWhere((a) => a.id == updatedAccount.id);
                if (index != -1) {
                  setState(() {
                    _accounts[index] = updatedAccount;
                    _accounts.sort((a, b) => (b.principal + b.interest)
                        .compareTo(a.principal + a.interest));
                  });
                  widget.onAccountUpdated();
                }
              },
              onDeleted: () => _deleteAccount(account.id),
            )),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}