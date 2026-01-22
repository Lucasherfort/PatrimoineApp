import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../ui/investment_detail_page.dart';

class InvestmentCard extends StatelessWidget {
  final int userInvestmentAccountId;
  final String type; // PEA / AV / CTO
  final String bankName;
  final String logoUrl;
  final double totalValue;
  final double totalContribution;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const InvestmentCard({
    super.key,
    required this.userInvestmentAccountId,
    required this.type,
    required this.bankName,
    required this.logoUrl,
    required this.totalValue,
    required this.totalContribution,
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

  Color _getValueColor() {
    final performance = totalValue - totalContribution;
    if (performance > 0) return Colors.purple.shade300;
    if (performance < 0) return Colors.red.shade400;
    return Colors.blueGrey.shade300;
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Confirmer la suppression',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            children: [
              const TextSpan(text: 'Êtes-vous sûr de vouloir supprimer le compte '),
              TextSpan(text: type, style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' de '),
              TextSpan(text: bankName, style: const TextStyle(fontWeight: FontWeight.bold)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && onDelete != null) onDelete!();
  }

  Widget _buildBankLogo() {
    if (logoUrl.isEmpty) {
      return Icon(Icons.trending_up, color: Colors.purple.shade300, size: 26);
    }

    return Image.network(
      logoUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(Icons.trending_up, color: Colors.purple.shade300, size: 26),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final shouldReload = await Navigator.of(context).push<bool>(
            PageRouteBuilder(
              opaque: true,
              barrierColor: const Color(0xFF0F172A), // 🔥 empêche le flash blanc
              transitionDuration: const Duration(milliseconds: 280),
              pageBuilder: (_, __, ___) => InvestmentDetailPage(
                userInvestmentAccountId: userInvestmentAccountId,
                accountName: type,
                bankName: bankName,
              ),
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

          if (shouldReload == true && onTap != null) onTap!();
        },
        onLongPress: () => _confirmDelete(context),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade900.withValues(alpha: 0.25),
                Colors.purple.shade800.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.purple.shade400.withValues(alpha: 0.3),
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
                /// Logo banque
                Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.purple.shade300.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildBankLogo(),
                  ),
                ),
                const SizedBox(width: 14),

                /// Infos à gauche
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bankName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                /// Valeur à droite avec couleur dynamique
                Text(
                  _formatAmount(totalValue),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _getValueColor(),
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