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
      accounts.sort(
        (a, b) =>
            (b.principal + b.interest).compareTo(a.principal + a.interest),
      );

      setState(() {
        _accounts = accounts;
      });
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
        if (snapshot.connectionState == ConnectionState.waiting &&
            _accounts.isEmpty) {
          return const SizedBox();
        }

        if (snapshot.hasError) {
          debugPrint('ERREUR SavingsAccountList snapshot: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Erreur de chargement : ${snapshot.error}',
              style: TextStyle(color: Colors.red.shade400),
            ),
          );
        }

        final List<UserSavingsAccountView> displayAccounts =
            snapshot.data ?? _accounts;

        if (displayAccounts.isEmpty) {
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
                      color: Colors.blue.shade400.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.savings_rounded,
                      color: isDark
                          ? Colors.blue.shade300
                          : Colors.blue.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Épargne",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  if (displayAccounts.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.blue.shade400.withValues(alpha: 0.15)
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade400.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${_formatAmount(displayAccounts.fold<double>(0, (sum, a) => sum + a.principal + a.interest))} €',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.blue.shade300
                              : Colors.blue.shade800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ...displayAccounts.map(
              (account) => SavingsAccountCard(
                account: account,
                onValueUpdated: (updatedAccount) {
                  setState(() {
                    _loadAccounts();
                  });
                  widget.onAccountUpdated();
                },
                onDeleted: () => _deleteAccount(account.id),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
