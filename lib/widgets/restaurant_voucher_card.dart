import 'package:flutter/material.dart';
import '../repositories/local_database_repository.dart';
import '../services/restaurant_voucher_service.dart';

class RestaurantVoucherCard extends StatelessWidget {
  final UserRestaurantVoucherView voucher;
  final void Function(double newValue)? onValueUpdated;
  final VoidCallback? onDeleted; // 🔹 Callback pour suppression

  const RestaurantVoucherCard({
    super.key,
    required this.voucher,
    this.onValueUpdated,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openEditPanel(context),
        onLongPress: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Confirmer la suppression'),
              content: const Text(
                  'Voulez-vous vraiment supprimer ce titre restaurant ?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Supprimer'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            final repo = LocalDatabaseRepository();
            final db = await repo.load();
            final service = RestaurantVoucherService(db);
            await service.deleteUserVoucher(voucher.id);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Titre restaurant supprimé'),
                backgroundColor: Colors.green,
              ),
            );

            // 🔹 Notifier le parent pour mettre à jour le patrimoine
            onDeleted?.call();
          }
        },
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Icône
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.restaurant,
                    color: Colors.orange.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Nom
                Expanded(
                  child: Text(
                    voucher.voucherName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),

                // Montant
                Text(
                  "${voucher.balance.toStringAsFixed(2).replaceAll('.', ',')} €",
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

  void _openEditPanel(BuildContext context) {
    final controller = TextEditingController(
      text: voucher.balance.toStringAsFixed(2).replaceAll('.', ','),
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
              const Text(
                "Modifier le solde",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: controller,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Nouveau montant",
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
}
