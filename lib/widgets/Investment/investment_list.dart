import 'package:flutter/material.dart';
import '../../models/investments/user_investment_account_view.dart';
import '../../services/investment_service.dart';
import 'investment_card.dart';

class InvestmentList extends StatefulWidget {
  final VoidCallback onAccountUpdated;

  const InvestmentList({super.key, required this.onAccountUpdated});

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
    _accountsFuture = _service.getUserInvestmentAccountsView().then((accounts) {
      accounts.sort((a, b) => b.amount.compareTo(a.amount));
      return accounts;
    });
  }

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}\u00A0',
    );
    return '$intPart,${parts[1]}';
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
          return const SizedBox();
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Erreur de chargement des comptes investissements',
              style: TextStyle(color: Colors.red.shade400),
            ),
          );
        }

        final accounts = snapshot.data ?? [];

        if (accounts.isEmpty) {
          return const SizedBox.shrink();
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
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
                      color: Colors.purple.shade400.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.trending_up,
                      color: isDark
                          ? Colors.purple.shade300
                          : Colors.purple.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Investissements",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                        color: isDark
                            ? Colors.purple.shade400.withValues(alpha: 0.15)
                            : Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.purple.shade400.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${_formatAmount(accounts.fold<double>(0, (sum, a) => sum + a.amount))} €',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.purple.shade300
                              : Colors.purple.shade800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ...accounts.map(
              (account) => InvestmentCard(
                userInvestmentAccountId: account.id,
                investmentCategoryId: account.investmentCategoryId,
                type: account.sourceName,
                bankName: account.bankName,
                logoUrl: account.logoUrl,
                totalValue: account.amount,
                totalContribution: account.totalContribution,
                openedAt: account.openedAt,
                onTap: widget.onAccountUpdated,
                onDelete: () => _deleteAccount(account.id),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
