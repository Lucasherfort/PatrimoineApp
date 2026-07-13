import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/investments/user_investment_account_view.dart';
import '../../services/investment_service.dart';
import '../../ui/investment_detail_page.dart';

class InvestmentCard extends StatelessWidget {
  final int userInvestmentAccountId;
  final int investmentCategoryId; // 👈 Ajouté
  final String type; // PEA / AV / CTO
  final String bankName;
  final String logoUrl;
  final double totalValue;
  final double totalContribution;
  final DateTime? openedAt;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const InvestmentCard({
    super.key,
    required this.userInvestmentAccountId,
    required this.investmentCategoryId, // 👈 Ajouté
    required this.type,
    required this.bankName,
    required this.logoUrl,
    required this.totalValue,
    required this.totalContribution,
    this.openedAt,
    this.onTap,
    this.onDelete,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirmer la suppression',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            children: [
              const TextSpan(
                text: 'Êtes-vous sûr de vouloir supprimer le compte ',
              ),
              TextSpan(
                text: type,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' de '),
              TextSpan(
                text: bankName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' ?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && onDelete != null) onDelete!();
  }

  Widget _buildBankLogo(BuildContext context) {
    if (logoUrl.isEmpty) {
      return Icon(Icons.trending_up, color: Colors.purple.shade300, size: 26);
    }

    return Image.network(
      logoUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          Icon(Icons.trending_up, color: Colors.purple.shade300, size: 26),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade300),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // On recrée une vue temporaire pour le calcul du Net
    final tempView = UserInvestmentAccountView(
      id: userInvestmentAccountId,
      investmentCategoryId: investmentCategoryId,
      sourceName: type,
      bankName: bankName,
      logoUrl: logoUrl,
      totalContribution: totalContribution,
      cashBalance: 0,
      amount: totalValue,
      openedAt: openedAt,
    );

    final displayValue = InvestmentService().calculateNetValue(tempView);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final shouldReload = await Navigator.of(context).push<bool>(
            PageRouteBuilder(
              opaque: true,
              barrierColor: Theme.of(context).scaffoldBackgroundColor,
              transitionDuration: const Duration(milliseconds: 280),
              pageBuilder: (_, _, _) => InvestmentDetailPage(
                userInvestmentAccountId: userInvestmentAccountId,
                investmentCategoryId: investmentCategoryId,
                accountName: type,
                bankName: bankName,
              ),
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

          if (shouldReload == true && onTap != null) onTap!();
        },
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
                    color: Colors.purple.shade400,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                /// Logo banque
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

                /// Infos à gauche
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bankName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// Valeur à droite
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    _formatAmount(displayValue),
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
}
