// step_category.dart
import 'package:flutter/material.dart';

import '../models/patrimoine_catalog.dart';
import '../models/patrimoine_category.dart';

class CategoryStep extends StatelessWidget {
  final PatrimoineCatalog catalog;
  final PatrimoineCategory? selectedCategory;
  final ValueChanged<PatrimoineCategory?> onChanged;

  const CategoryStep({
    super.key,
    required this.catalog,
    this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<PatrimoineCategory>(
      decoration: const InputDecoration(
        labelText: "Catégorie",
        border: OutlineInputBorder(),
      ),
      value: selectedCategory,
      items: catalog.categories
          .map((cat) => DropdownMenuItem(
        value: cat,
        child: Text(cat.name),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }
}