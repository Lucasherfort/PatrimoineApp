import 'package:flutter/material.dart';
import '../repositories/local_database_repository.dart';
import '../services/investment_service.dart';
import 'investment_card.dart';

class InvestmentList extends StatefulWidget {
  final int userId;

  const InvestmentList({
    super.key,
    required this.userId,
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
    try {
      final repo = LocalDatabaseRepository();
      final db = await repo.load();
      final service = InvestmentService(db);

      final data = service.getInvestmentAccountsForUser(widget.userId);

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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Mes placements financiers",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isLoading && errorMessage == null)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                    });
                    _loadInvestmentAccounts();
                  },
                ),
            ],
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
                  Text(
                    errorMessage!,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (accounts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Aucun placement disponible'),
                ),
              )
            else
              ...accounts.map((account) => InvestmentCard(
                userInvestmentAccountId: account.id,
                name: account.investmentAccountName,
                type: account.investmentAccountName,
                bankName: account.bankName,
                value: account.balance,
                performance: account.balance > 0
                    ? (account.latentCapitalGain / account.balance) * 100
                    : 0.0,
              )),
        ],
      ),
    );
  }
}