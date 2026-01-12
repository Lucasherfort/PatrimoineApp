import 'package:flutter/material.dart';
import '../../models/investments/UserInvestmentAccountView.dart';
import '../../services/investment_service.dart';
import 'investment_card.dart';

class InvestmentList extends StatefulWidget {
  final VoidCallback onAccountUpdated;

  const InvestmentList({
    super.key,
    required this.onAccountUpdated,
  });

  @override
  State<InvestmentList> createState() => _InvestmentListState();
}

class _InvestmentListState extends State<InvestmentList> {
  final InvestmentService _service = InvestmentService();
  late Future<List<UserInvestmentAccountView>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() {
    _accountsFuture = _service.getUserInvestmentAccountsView();
  }

  Future<void> _deleteAccount(int accountId) async {
    await _service.deleteUserInvestmentAccount(accountId);
    widget.onAccountUpdated();
    setState(_loadAccounts);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserInvestmentAccountView>>(
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
              'Erreur de chargement des comptes investissements',
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
                "Investissements",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...accounts.map(
                  (account) => InvestmentCard(
                userInvestmentAccountId: account.id,
                type: account.sourceName,
                bankName: account.bankName,
                totalValue: account.amount,
                totalContribution: account.totalContribution, // ✅ Ajoutez cette ligne
                onTap: widget.onAccountUpdated,
                onDelete: () => _deleteAccount(account.id),
              ),
            ),
          ],
        );
      },
    );
  }
}
