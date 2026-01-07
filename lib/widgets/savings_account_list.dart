import 'package:flutter/material.dart';
import '../repositories/local_database_repository.dart';
import '../services/savings_account_service.dart';
import 'savings_account_card.dart';

class SavingsAccountList extends StatefulWidget {
  final int userId;
  final VoidCallback? onAccountUpdated;

  const SavingsAccountList({
    super.key,
    required this.userId,
    this.onAccountUpdated,
  });

  @override
  State<SavingsAccountList> createState() => _SavingsAccountListState();
}

class _SavingsAccountListState extends State<SavingsAccountList> {
  List<UserSavingsAccountView> accounts = [];
  bool isLoading = true;
  String? errorMessage;
  SavingsAccountService? savingsAccountService;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final repo = LocalDatabaseRepository();
      final db = await repo.load();
      final service = SavingsAccountService(db);

      final data = service.getAccountsForUser(widget.userId);

      setState(() {
        accounts = data;
        savingsAccountService = service;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _updateAccount(int accountId, double newBalance, double newInterest) async {
    if (savingsAccountService != null) {
      final success = await savingsAccountService!.updateSavingsAccount(accountId, newBalance, newInterest);

      if (success) {
        await _loadAccounts();

        if (widget.onAccountUpdated != null) {
          widget.onAccountUpdated!();
        }
      }
    }
  }

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

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (errorMessage != null)
            Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ],
              ),
            )
          else if (accounts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Aucun compte épargne'),
                ),
              )
            else
              ...accounts.map((account) => SavingsAccountCard(
                account: account,
                onValueUpdated: (newBalance, newInterest) =>
                    _updateAccount(account.id, newBalance, newInterest),
              )),
        ],
      ),
    );
  }
}