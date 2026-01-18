import 'package:flutter/material.dart';
import '../../models/savings/user_savings_account_view.dart';
import '../../services/savings_account_service.dart';
import 'savings_account_card.dart';

class SavingsAccountList extends StatefulWidget {
  final VoidCallback onAccountUpdated; // Callback vers HomePage

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
      setState(() {
        _accounts = accounts; // On garde une copie locale
      });
    });
  }

  Future<void> _deleteAccount(int accountId) async {
    await _service.deleteSavingsAccount(accountId);
    _accounts.removeWhere((a) => a.id == accountId);
    setState(() {}); // Rebuild la liste
    widget.onAccountUpdated(); // Remonte vers HomePage pour recalcul
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

        if (_accounts.isEmpty) {
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
            ..._accounts.map((account) => SavingsAccountCard(
              account: account,
              onValueUpdated: (updatedAccount) {
                // 🔥 Remplacer l'objet existant dans la liste
                final index =
                _accounts.indexWhere((a) => a.id == updatedAccount.id);
                if (index != -1) {
                  setState(() {
                    _accounts[index] = updatedAccount;
                  });
                  widget.onAccountUpdated(); // Recalcule patrimoine
                }
              },
              onDeleted: () => _deleteAccount(account.id),
            )),
          ],
        );
      },
    );
  }
}
