import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/local_database_repository.dart';
import '../services/cash_account_service.dart';

class CashAccountCard extends StatelessWidget {
  final UserCashAccountView account;
  final void Function(double newValue)? onValueUpdated;
  final VoidCallback? onDeleted; // ✅ AJOUT

  const CashAccountCard({
    super.key,
    required this.account,
    this.onValueUpdated,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat =
    NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openEditPanel(context),
        onLongPress: () => _confirmDelete(context), // ✅ Appui long
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.cashAccountName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        account.bankName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormat.format(account.balance),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEditPanel(BuildContext context) {
    final controller = TextEditingController(
      text: account.balance.toStringAsFixed(2).replaceAll('.', ','),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Modifier ${account.cashAccountName}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Nouveau montant",
                  suffixText: "€",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final value = double.tryParse(
                      controller.text.replaceAll(',', '.'),
                    );

                    if (value != null && onValueUpdated != null) {
                      onValueUpdated!(value);
                    }

                    Navigator.pop(context);
                  },
                  child: const Text("Valider"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Supprimer le compte"),
          content: Text(
              "Voulez-vous vraiment supprimer le compte ${account.cashAccountName} ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                final service = CashAccountService(
                  await LocalDatabaseRepository().load(),
                );

                await service.deleteCashAccount(account.id);

                Navigator.pop(context);

                // ✅ NOTIFIER LE PARENT
                onDeleted?.call();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Compte ${account.cashAccountName} supprimé.",
                    ),
                  ),
                );
              },
              child: const Text("Supprimer"),
            ),
          ],
        );
      },
    );
  }
}