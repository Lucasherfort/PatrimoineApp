import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/patrimoine/real_estate_asset.dart';
import '../../ui/real_estate_detail_page.dart';

class RealEstateAssetCard extends StatelessWidget {
  final RealEstateAsset asset;
  final VoidCallback? onUpdated;
  final VoidCallback? onDeleted;

  const RealEstateAssetCard({
    super.key,
    required this.asset,
    this.onUpdated,
    this.onDeleted,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirmer la suppression',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text("Voulez-vous vraiment supprimer « ${asset.label} » ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (onDeleted != null) onDeleted!();
            },
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
  }

  IconData _getIconForCategory(String category) {
    if (category.contains('Principale')) return Icons.home_rounded;
    if (category.contains('Secondaire')) return Icons.beach_access_rounded;
    if (category.contains('Locatif')) return Icons.apartment_rounded;
    if (category.contains('Caution')) return Icons.security_rounded;
    return Icons.account_balance_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RealEstateDetailPage(asset: asset),
            ),
          );
          if (result == true && onUpdated != null) onUpdated!();
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
                    color: Colors.orange.shade400,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                /// Icône de l'actif
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
                  child: Icon(
                    _getIconForCategory(asset.categoryName),
                    color: Colors.orange.shade300,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                /// Infos à gauche
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ), // Ajusté de 14 à 12
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          asset.label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          asset.categoryName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                /// Valeur à droite
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      _formatAmount(asset.amount),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
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
