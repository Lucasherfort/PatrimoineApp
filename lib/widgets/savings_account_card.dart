import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/savings_account_service.dart';

class SavingsAccountCard extends StatelessWidget {
  final UserSavingsAccountView account;
  final void Function(double newBalance, double newInterest)? onValueUpdated;

  const SavingsAccountCard({
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
                // Icône
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Nom du compte + banque
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.savingsAccountName,
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

                // ✅ UN SEUL affichage : le solde
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

  // ---------------------------
  // Modal d'édition (inchangé)
  // ---------------------------
  void _openEditPanel(BuildContext context) {
    final balanceController = TextEditingController(
      text: account.balance.toStringAsFixed(2).replaceAll('.', ','),
    );
    final interestController = TextEditingController(
      text: account.interestAccrued.toStringAsFixed(2).replaceAll('.', ','),
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
                "Modifier ${account.savingsAccountName}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: balanceController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Solde",
                  suffixText: "€",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: interestController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Intérêts accumulés",
                  suffixText: "€",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final balance = double.tryParse(
                      balanceController.text.replaceAll(',', '.'),
                    );
                    final interest = double.tryParse(
                      interestController.text.replaceAll(',', '.'),
                    );

                    if (balance != null &&
                        interest != null &&
                        onValueUpdated != null) {
                      onValueUpdated!(balance, interest);
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
