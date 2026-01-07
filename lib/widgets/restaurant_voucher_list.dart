import 'package:flutter/material.dart';
import '../repositories/local_database_repository.dart';
import '../services/restaurant_voucher_service.dart';
import 'restaurant_voucher_card.dart';

class RestaurantVoucherList extends StatefulWidget {
  final int userId;
  final VoidCallback? onVoucherUpdated; // ✅ Callback pour notifier le parent

  const RestaurantVoucherList({
    super.key,
    required this.userId,
    this.onVoucherUpdated,
  });

  @override
  State<RestaurantVoucherList> createState() => _RestaurantVoucherListState();
}

class _RestaurantVoucherListState extends State<RestaurantVoucherList> {
  List<UserRestaurantVoucherView> vouchers = [];
  bool isLoading = true;
  String? errorMessage;
  RestaurantVoucherService? voucherService;

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
        voucherService = service;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _updateVoucherBalance(int voucherId, double newBalance) async {
    if (voucherService != null) {
      final success = await voucherService!.updateVoucherBalance(voucherId, newBalance);

      // ✅ Ne recharge que si la valeur a changé
      if (success) {
        await _loadVouchers();

        if (widget.onVoucherUpdated != null) {
          widget.onVoucherUpdated!();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
          const SizedBox(height: 16),

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (errorMessage != null)
            Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
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
                  padding: EdgeInsets.all(20.0),
                  child: Text('Aucun titre restaurant'),
                ),
              )
            else
              ...vouchers.map((voucher) => RestaurantVoucherCard(
                voucher: voucher,
                onValueUpdated: (newValue) => _updateVoucherBalance(voucher.id, newValue),
              )),
        ],
      ),
    );
  }
}