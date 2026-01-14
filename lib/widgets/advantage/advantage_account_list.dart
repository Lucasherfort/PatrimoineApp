import 'package:flutter/material.dart';
import '../../services/advantage_service.dart';
import '../../models/advantage/user_advantage_account_view.dart';
import 'advantage_account_card.dart';

class AdvantageAccountList extends StatefulWidget {
  final VoidCallback onAccountUpdated;

  const AdvantageAccountList({
    super.key,
    required this.onAccountUpdated,
  });

  @override
  State<AdvantageAccountList> createState() => _AdvantageAccountListState();
}

class _AdvantageAccountListState extends State<AdvantageAccountList> {
  final AdvantageService _service = AdvantageService();
  late Future<List<UserAdvantageAccountView>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() {
    _accountsFuture = _service.getUserAdvantageAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserAdvantageAccountView>>(
      future: _accountsFuture,
      builder: (context, snapshot) {
        // 👇 Retirer le loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(); // Rien pendant le chargement
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Erreur de chargement des avantages',
              style: TextStyle(color: Colors.red.shade700),
            ),
          );
        }

        final accounts = snapshot.data ?? [];

        if (accounts.isEmpty) {
          return const SizedBox(); // rien si vide
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Avantages",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...accounts.map((account) => AdvantageAccountCard(
              account: account,
              onValueUpdated: (newValue) async {
                await _service.updateValue(
                    accountId: account.id, value: newValue);
                widget.onAccountUpdated();
                setState(_loadAccounts);
              },
              onDeleted: () async {
                await _service.deleteAccount(account.id);
                widget.onAccountUpdated();
                setState(_loadAccounts);
              },
            )),
          ],
        );
      },
    );
  }
}