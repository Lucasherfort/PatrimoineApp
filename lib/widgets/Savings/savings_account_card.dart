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

  Color _getAmountColor(double amount) {
    if (amount > 0) return Colors.blue.shade300;
    if (amount < 0) return Colors.red.shade400;
    return Colors.blueGrey.shade300;
  }

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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade900.withValues(alpha: 0.25),
                Colors.blue.shade800.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.blue.shade400.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Logo banque
                Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.shade300.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildBankLogo(),
                  ),
                ),
                const SizedBox(width: 14),
                // Nom + banque
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.sourceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account.bankName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Montant total avec couleur dynamique
                Text(
                  currencyFormat.format(total),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _getAmountColor(total),
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
        barrierColor: const Color(0xFF0F172A),
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) =>
            SavingsDetailPage(account: account),
        transitionsBuilder: (_, animation, __, child) {
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
  Widget _buildBankLogo() {
    if (account.logoUrl.isEmpty) {
      return Icon(
        Icons.account_balance,
        color: Colors.blue.shade300,
        size: 26,
      );
    }

    return Image.network(
      account.logoUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(
        Icons.account_balance,
        color: Colors.blue.shade300,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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