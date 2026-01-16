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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openEditPanel(context),
        onLongPress: () => _confirmDelete(context),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Widget pour afficher le logo du fournisseur
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
                      Text(
                        account.providerName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormat.format(account.value),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderLogo() {
    // Si pas de logo, afficher l'icône par défaut
    if (account.logoUrl.isEmpty) {
      return Icon(
        Icons.card_giftcard,
        color: Colors.blue.shade700,
        size: 24,
      );
    }

    // Afficher l'image (PNG, JPG, etc.)
    return Image.network(
      account.logoUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        print('Erreur chargement image: $error');
        return Icon(
          Icons.card_giftcard,
          color: Colors.blue.shade700,
          size: 24,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
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
                "Modifier ${account.sourceName} - ${account.providerName}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                    final value = double.tryParse(
                      controller.text.replaceAll(',', '.'),
                    );

                    if (value != null && onValueUpdated != null) {
                      onValueUpdated!(value);
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

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Supprimer l'avantage"),
          content: Text(
              "Voulez-vous vraiment supprimer ${account.sourceName} - ${account.providerName} ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                navigator.pop();

                final service = AdvantageService();
                await service.deleteAccount(account.id);

                onDeleted?.call();

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      "Avantage ${account.sourceName} - ${account.providerName} supprimé.",
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