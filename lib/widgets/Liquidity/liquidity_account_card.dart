import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/liquidity/user_liquidity_account_view.dart';
import '../../services/liquidity_service.dart';
import '../../ui/liquidity_detail_page.dart';

class LiquidityAccountCard extends StatelessWidget {
  final UserLiquidityAccountView account;
  final void Function(double newValue)? onValueUpdated;
  final VoidCallback? onDeleted;

  const LiquidityAccountCard({
    super.key,
    required this.account,
    this.onValueUpdated,
    this.onDeleted,
  });

  Future<void> _openDetailPage(BuildContext context) async {
    final result = await Navigator.of(context).push<UserLiquidityAccountView?>(
      PageRouteBuilder(
        barrierColor: Theme.of(context).scaffoldBackgroundColor,
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => LiquidityDetailPage(account: account),
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

    if (result != null && onValueUpdated != null) {
      onValueUpdated!(result.amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetailPage(context),
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
                    color: Colors.amber.shade400,
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
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    currencyFormat.format(account.amount),
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

  Widget _buildBankLogo(BuildContext context) {
    if (account.logoUrl.isEmpty) {
      return Icon(Icons.euro_rounded, color: Colors.amber.shade300, size: 26);
    }
    return Image.network(
      account.logoUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.euro_rounded, color: Colors.amber.shade300, size: 26),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade300),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Supprimer le compte"),
          content: Text(
            "Voulez-vous vraiment supprimer le compte ${account.sourceName} ?",
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
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                navigator.pop();
                final service = LiquidityService();
                await service.deleteAccount(account.id);
                onDeleted?.call();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text("Compte ${account.sourceName} supprimé."),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
