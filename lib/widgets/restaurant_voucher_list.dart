import 'package:flutter/material.dart';
import '../repositories/local_database_repository.dart';
import '../services/restaurant_voucher_service.dart';
import 'restaurant_voucher_card.dart';

class RestaurantVoucherList extends StatefulWidget {
  final int userId;

  const RestaurantVoucherList({
    super.key,
    required this.userId,
  });

  @override
  State<RestaurantVoucherList> createState() => _RestaurantVoucherListState();
}

class _RestaurantVoucherListState extends State<RestaurantVoucherList> {
  List<UserRestaurantVoucherView> vouchers = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    try {
      final repo = LocalDatabaseRepository();
      final db = await repo.load();
      final service = RestaurantVoucherService(db);

      final data = service.getVouchersForUser(widget.userId);

      setState(() {
        vouchers = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _updateVoucherBalance(String voucherName, double newBalance) async {
    try {
      final repo = LocalDatabaseRepository();
      final db = await repo.load();
      final service = RestaurantVoucherService(db);

      service.updateVoucherBalance(
        userId: widget.userId,
        voucherName: voucherName,
        newBalance: newBalance,
      );

      // Recharge la liste avec les nouvelles valeurs
      final updatedVouchers = service.getVouchersForUser(widget.userId);

      setState(() {
        vouchers = updatedVouchers;
      });
    } catch (e) {
      // Optionnel : afficher une erreur si update échoue
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mes titres restaurant",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (errorMessage != null)
            Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 6),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ],
              ),
            )
          else if (vouchers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('Aucun titre restaurant'),
                ),
              )
            else
              ...vouchers.map(
                    (voucher) => RestaurantVoucherCard(
                  voucher: voucher,
                  onValueUpdated: (newValue) {
                    _updateVoucherBalance(voucher.voucherName, newValue);
                  },
                ),
              ),
        ],
      ),
    );
  }
}