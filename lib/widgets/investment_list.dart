import 'package:flutter/material.dart';
import '../repositories/local_database_repository.dart';
import '../services/investment_service.dart';
import 'investment_card.dart';

class InvestmentList extends StatefulWidget {
  final int userId;
  final VoidCallback? onAccountTap;
  final VoidCallback? onAccountUpdated;

  const InvestmentList({
    super.key,
    required this.userId,
    this.onAccountTap,
    this.onAccountUpdated,
  });

  @override
  State<InvestmentList> createState() => _InvestmentListState();
}

class _InvestmentListState extends State<InvestmentList> {
  List<UserInvestmentAccountView> accounts = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvestmentAccounts();
  }

  Future<void> _loadInvestmentAccounts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final repo = LocalDatabaseRepository();
      final db = await repo.load();
      final service = InvestmentService(db);

      final data = await service.getInvestmentAccountsForUserWithPrices(widget.userId);

      setState(() {
        accounts = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(fontSize: 14, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // 🔹 Rien si aucun compte
    if (accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    // 🔹 Sinon, on affiche le label + les cartes
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Investissements",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...accounts.map(
                (account) => InvestmentCard(
              userInvestmentAccountId: account.id,
              name: account.investmentAccountName,
              type: account.investmentAccountName,
              bankName: account.bankName,
              totalValue: account.totalValue,
              performance: account.performance,
              onTap: widget.onAccountTap,
              onDelete: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Confirmer la suppression'),
                    content: const Text(
                        'Voulez-vous vraiment supprimer ce compte et toutes ses positions ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  final repo = LocalDatabaseRepository();
                  final db = await repo.load();
                  final service = InvestmentService(db);

                  await service.deleteUserInvestmentAccount(account.id);

                  // 🔹 Recharger la liste locale
                  await _loadInvestmentAccounts();

                  // 🔹 Rafraîchir le patrimoine global via callback
                  widget.onAccountUpdated?.call();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Compte supprimé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

