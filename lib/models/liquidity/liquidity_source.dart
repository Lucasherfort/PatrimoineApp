import '../bank.dart';

class LiquiditySource {
  final int id;
  final int categoryId; // PatrimoineCategory.id = 1 (Liquidités)
  final String name; // Cash liquide / Compte espèce
  final Bank? bank;

  LiquiditySource({
    required this.id,
    required this.categoryId,
    required this.name,
    this.bank,
  });
}