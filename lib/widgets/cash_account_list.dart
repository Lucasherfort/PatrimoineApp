import 'package:flutter/material.dart';
import '../repositories/local_database_repository.dart';
import '../services/cash_account_service.dart';
import 'cash_account_card.dart';

class CashAccountList extends StatefulWidget {
  final int userId;
  final VoidCallback? onAccountUpdated;

  const CashAccountList({
    super.key,
    required this.userId,
    this.onAccountUpdated,
  });

  @override
  State<CashAccountList> createState() => _CashAccountListState();
}

class _CashAccountListState extends State<CashAccountList> {
  List<UserCashAccountView> accounts = [];
  bool isLoading = true;
  String? errorMessage;
  CashAccountService? cashAccountService;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final repo = LocalDatabaseRepository();
      final db = await repo.load();
      final service = CashAccountService(db);

      final data = service.getAccountsForUser(widget.userId);

      setState(() {
        accounts = data;
        cashAccountService = service;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _updateAccountBalance(int accountId, double newBalance) async {
    if (cashAccountService != null) {
      final success = await cashAccountService!.updateCashAccountBalance(accountId, newBalance);

      // ✅ Ne recharge que si la valeur a changé
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
            "Mes comptes espèces",
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
                  child: Text('Aucun compte espèces'),
                ),
              )
            else
              ...accounts.map((account) => CashAccountCard(
                account: account,
                onValueUpdated: (newValue) => _updateAccountBalance(account.id, newValue),
              )),
        ],
      ),
    );
  }
}