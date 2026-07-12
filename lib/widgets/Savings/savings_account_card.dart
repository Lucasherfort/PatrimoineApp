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
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final double total = account.principal + account.interest;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetailsPage(context),
        onLongPress: () => _confirmDelete(context),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Barre d'accentuation à gauche
                Container(
                  width: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade400,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Logo banque
                Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildBankLogo(context),
                  ),
                ),
                const SizedBox(width: 14),
                // Nom + banque
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.sourceName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.bankName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Montant total
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    currencyFormat.format(total),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
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
    final result = await Navigator.of(context).push<UserSavingsAccountView?>(
      PageRouteBuilder(
        barrierColor: Theme.of(context).scaffoldBackgroundColor,
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => SavingsDetailPage(account: account),
        transitionsBuilder: (_, animation, _, child) {
          final tween = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );

    if (result != null) onValueUpdated?.call(result);
  }

  // =========================
  // Logo banque
  // =========================
  Widget _buildBankLogo(BuildContext context) {
    if (account.logoUrl.isEmpty) {
      return Icon(Icons.account_balance, color: Colors.blue.shade300, size: 26);
    }

    return Image.network(
      account.logoUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          Icon(Icons.account_balance, color: Colors.blue.shade300, size: 26),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade300),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
