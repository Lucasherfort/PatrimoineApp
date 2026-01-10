class SavingsCategory {
  final int id;
  final String name;
  final double interestRate; // ex: 0.024
  final double ceiling;

  SavingsCategory({
    required this.id,
    required this.name,
    required this.interestRate,
    required this.ceiling,
  });
}