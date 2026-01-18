import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/advantage/user_advantage_account_view.dart';
import '../../services/advantage_service.dart';

class AdvantageAccountCard extends StatelessWidget {
  final UserAdvantageAccountView account;
  final void Function(double newValue)? onValueUpdated;
  final VoidCallback? onDeleted;

  const AdvantageAccountCard({
    super.key,
    required this.account,
    this.onValueUpdated,
    this.onDeleted,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 2);
    return formatter.format(amount);
  }

  Color _getValueColor() {
    if (account.value > 0) return Colors.blue.shade700;
    if (account.value < 0) return Colors.red.shade600;
    return Colors.purple.shade400; // neutre pour 0,00€
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openEditPanel(context),
        onLongPress: () => _confirmDelete(context),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Logo fournisseur
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _buildProviderLogo(),
                  ),
                ),
                const SizedBox(width: 12),
                // Nom + fournisseur
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.sourceName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(account.providerName,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                // Valeur
                Text(
                  _formatAmount(account.value),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getValueColor()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderLogo() {
    if (account.logoUrl.isEmpty) {
      return Icon(Icons.card_giftcard, color: Colors.blue.shade700, size: 24);
    }

    return Image.network(
      account.logoUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(Icons.card_giftcard, color: Colors.blue.shade700, size: 24),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
          ),
        );
      },
    );
  }

  void _openEditPanel(BuildContext context) {
    final controller = TextEditingController(
      text: account.value.toStringAsFixed(2).replaceAll('.', ','),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
              Text("Modifier ${account.sourceName} - ${account.providerName}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Nouvelle valeur",
                  suffixText: "€",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final value = double.tryParse(controller.text.replaceAll(',', '.'));
                    if (value != null && onValueUpdated != null) onValueUpdated!(value);
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
  void _confirmDelete(BuildContext context) async {
    // 1️⃣ Afficher le dialog et attendre la confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer l'avantage"),
        content: Text(
          "Voulez-vous vraiment supprimer ${account.sourceName} - ${account.providerName} ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 2️⃣ Appeler le service async SANS context
    await AdvantageService().deleteAccount(account.id);

    // 3️⃣ Utiliser les callbacks pour signaler la suppression au parent
    onDeleted?.call();

    // 4️⃣ Ensuite, seulement utiliser le context pour le SnackBar
    // ✅ Ça ne pose plus de warning car il n’y a pas d’`await` entre
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Avantage ${account.sourceName} - ${account.providerName} supprimé."),
      ),
    );
  }
}
