import 'package:patrimoine/models/patrimoine/patrimoine_category.dart';

import '../bank.dart';

class PatrimoineWizardItem {
  final PatrimoineCategory category;
  final dynamic source; // LiquiditySource | SavingsCategory
  final Bank? bank;     // si applicable

  PatrimoineWizardItem({
    required this.category,
    required this.source,
    this.bank,
  });
}