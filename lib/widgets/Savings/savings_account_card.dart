import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/savings/user_savings_account_view.dart';
import '../../ui/savings_detail_page.dart';

class SavingsAccountCard extends StatelessWidget {
  final UserSavingsAccountView account;
  final void Function(UserSavingsAccountView updatedAccount)? onValueUpdated;
  final VoidCallback? onDeleted;

  const SavingsAccountCard({
    super.key,
    required this.account,
    this.onValueUpdated,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat =
    NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    final double total = account.principal + account.interest;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDetailsPage(context),
        onLongPress: () => _confirmDelete(context),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Logo banque
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _buildBankLogo(),
                  ),
                ),
                const SizedBox(width: 12),
                // Nom + banque
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.sourceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
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
                // Montant total
                Text(
                  currencyFormat.format(total),
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

  // =========================
  // Navigation
  // =========================
  Future<void> _openDetailsPage(BuildContext context) async {
    final result = await Navigator.push<UserSavingsAccountView?>(
      context,
      MaterialPageRoute(
        builder: (_) => SavingsDetailPage(account: account),
      ),
    );

    if (result != null) {
      // ⚡️ Remonte le nouvel objet vers le parent
      onValueUpdated?.call(result);
    }
  }

  // =========================
  // Logo banque
  // =========================
  Widget _buildBankLogo() {
    if (account.logoUrl.isEmpty) {
      return Icon(
        Icons.account_balance,
        color: Colors.blue.shade700,
        size: 26,
      );
    }

    return Image.network(
      account.logoUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, _, __) => Icon(
        Icons.account_balance,
        color: Colors.blue.shade700,
        size: 26,
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.blue.shade700,
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================
  // Suppression
  // =========================
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer le compte"),
        content: Text(
          "Voulez-vous vraiment supprimer le compte « ${account.sourceName} » ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              onDeleted?.call();
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }
}
