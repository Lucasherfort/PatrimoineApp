import 'package:flutter/material.dart';
import '../models/bank.dart';
import '../models/patrimoine_type.dart';

class BankStep extends StatelessWidget {
  final PatrimoineType type;
  final List<Bank> banks;
  final List<RestaurantVoucher> vouchers;
  final Bank? selectedBank;
  final RestaurantVoucher? selectedVoucher;
  final void Function(Bank?, RestaurantVoucher?) onChanged;

  const BankStep({
    super.key,
    required this.type,
    required this.banks,
    required this.vouchers,
    this.selectedBank,
    this.selectedVoucher,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = type.entityType == 'restaurantVoucher'
        ? vouchers
        .map((v) => DropdownMenuItem(
      value: v,
      child: Text(v.name),
    ))
        .toList()
        : banks
        .map((b) => DropdownMenuItem(
      value: b,
      child: Text(b.name),
    ))
        .toList();

    return DropdownButtonFormField<Object>(
      decoration: InputDecoration(
        labelText: type.entityType == 'restaurantVoucher' ? "Plateforme" : "Banque",
        border: const OutlineInputBorder(),
      ),
      initialValue: type.entityType == 'restaurantVoucher' ? selectedVoucher : selectedBank,
      items: items,
      onChanged: (value) {
        if (value is Bank) {
          onChanged(value, null);
        } else if (value is RestaurantVoucher) {
          onChanged(null, value);
        }
      },
    );
  }
}
