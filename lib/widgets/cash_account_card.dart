import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/cash_account_service.dart';

class CashAccountCard extends StatelessWidget {
  final UserCashAccountView account;
  final void Function(double newValue)? onValueUpdated;

  const CashAccountCard({
    super.key,
    required this.account,
    this.onValueUpdated,
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
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Icône à gauche
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

                // Infos principales (compte + banque)
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

                // Montant à droite (format français)
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
}