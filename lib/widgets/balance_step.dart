import 'package:flutter/material.dart';

class BalanceStep extends StatelessWidget {
  final double? initialBalance;
  final ValueChanged<double> onChanged;

  const BalanceStep({
    super.key,
    this.initialBalance,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: initialBalance?.toStringAsFixed(2).replaceAll('.', ',') ?? '',
    );

    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: "Solde initial (€)",
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        final val = double.tryParse(value.replaceAll(',', '.'));
        if (val != null) onChanged(val);
      },
    );
  }
}
