import 'package:flutter/material.dart';
import '../repositories/local_database_repository.dart';
import '../services/restaurant_voucher_service.dart';
import 'restaurant_voucher_card.dart';

class RestaurantVoucherList extends StatefulWidget {
  final int userId;
  final VoidCallback? onVoucherUpdated; // Callback pour notifier le parent / patrimoine global

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
  LocalDatabaseRepository? repo;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      repo ??= LocalDatabaseRepository();
      final db = await repo!.load();
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
      if (success) {
        await _loadVouchers();
        widget.onVoucherUpdated?.call();
      }
    }
  }

  Future<void> _deleteVoucher(int voucherId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce titre restaurant ?'),
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

    if (confirmed != true) return;

    if (voucherService != null && repo != null) {
      final db = await repo!.load();
      final service = RestaurantVoucherService(db);
      await service.deleteUserVoucher(voucherId);

      await _loadVouchers();
      widget.onVoucherUpdated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Titre restaurant supprimé'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(fontSize: 14, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (vouchers.isEmpty) return const SizedBox.shrink(); // 🔹 Pas de catégorie si vide

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Avantages",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...vouchers.map((voucher) => RestaurantVoucherCard(
            voucher: voucher,
            onValueUpdated: (newValue) => _updateVoucherBalance(voucher.id, newValue),
            onDeleted: () async {
              if (voucherService != null) {
                await voucherService! .deleteUserVoucher(voucher.id); // supprimer dans la DB
                await _loadVouchers(); // recharger la liste
                if (widget.onVoucherUpdated != null) {
                  widget.onVoucherUpdated!(); // mettre à jour le patrimoine
                }
              }
            },
          )),
        ],
      ),
    );
  }
}