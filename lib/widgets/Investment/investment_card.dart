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
    if (performance > 0) return Colors.green.shade600;
    if (performance < 0) return Colors.red.shade600;
    return Colors.purple.shade400; // neutre pour 0,00€
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
            style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && onDelete != null) onDelete!();
  }

  Widget _buildBankLogo() {
    if (logoUrl.isEmpty) {
      return Icon(Icons.trending_up, color: Colors.purple.shade700, size: 24);
    }

    return Image.network(
      logoUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(Icons.trending_up, color: Colors.purple.shade700, size: 24),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade700),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final shouldReload = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => InvestmentDetailPage(
                userInvestmentAccountId: userInvestmentAccountId,
                accountName: type,
                bankName: bankName,
              ),
            ),
          );

          if (shouldReload == true && onTap != null) onTap!();
        },
        onLongPress: () => _confirmDelete(context),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                /// Logo banque
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(6), child: _buildBankLogo()),
                ),
                const SizedBox(width: 12),

                /// Infos à gauche
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(bankName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),

                /// Valeur à droite avec couleur dynamique
                Text(
                  _formatAmount(totalValue),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getValueColor()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
