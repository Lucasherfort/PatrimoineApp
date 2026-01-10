import 'package:flutter/material.dart';
import '../models/patrimoine/patrimoine_category.dart';
import '../models/patrimoine_type.dart';
import '../models/patrimoine_catalog.dart';

class TypeStep extends StatelessWidget {
  final PatrimoineCategory category;
  final PatrimoineCatalog catalog;
  final PatrimoineType? selectedType;
  final ValueChanged<PatrimoineType?> onChanged;

  const TypeStep({
    super.key,
    required this.category,
    required this.catalog,
    this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final types = catalog.getTypesForCategory(category.id);

    return DropdownButtonFormField<PatrimoineType>(
      decoration: const InputDecoration(
        labelText: "Type de compte",
        border: OutlineInputBorder(),
      ),
      initialValue: selectedType,
      items: types
          .map((t) => DropdownMenuItem(
        value: t,
        child: Text(t.name),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
