import '../bank.dart';

class SavingsSource {
  final int id;
  final SavingsCategory category;
  final Bank? bank;

  SavingsSource({required this.id, required this.category, this.bank});
}

class SavingsCategory {
  final String name;
  final double interestRate;
  final double ceiling;

  SavingsCategory({required this.name, required this.interestRate, required this.ceiling});
}