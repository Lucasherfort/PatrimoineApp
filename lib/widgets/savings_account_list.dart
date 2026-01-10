import 'package:flutter/material.dart';
import '../repositories/local_database_repository.dart';
import '../services/bank_service.dart';
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

      // ✅ Créer BankService
      final bankService = BankService(db.banks);

      // ✅ Créer SavingsAccountService avec db + bankService
      final service = SavingsAccountService(db, bankService);

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

  Future<void> _updateAccount(
      int accountId, double newBalance, double newInterest) async {
    if (savingsAccountService != null) {
      // ✅ Utiliser des paramètres nommés
      final success = await savingsAccountService!.updateSavingsAccount(
        accountId: accountId,           // ✅ Avec le nom
        balance: newBalance,             // ✅ Avec le nom
        interestAccrued: newInterest,    // ✅ Avec le nom
      );

      if (success) {
        await _loadAccounts();
        widget.onAccountUpdated?.call();
      }
    }
  }

  Future<void> _deleteAccount(int accountId) async {
    if (savingsAccountService != null) {
      await savingsAccountService!.deleteSavingsAccount(accountId);
      await _loadAccounts();
      widget.onAccountUpdated?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Si aucun compte, ne rien afficher
    if (!isLoading && accounts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Épargne",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
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
          else
            ...accounts.map(
                  (account) => SavingsAccountCard(
                account: account,
                onValueUpdated: (newBalance, newInterest) =>
                    _updateAccount(account.id, newBalance, newInterest),
                onDeleted: () => _deleteAccount(account.id),
              ),
            ),
        ],
      ),
    );
  }
}
