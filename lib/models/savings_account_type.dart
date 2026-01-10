// 📁 models/savings_account_type.dart

class SavingsAccountType {
  final int id;
  final String name;
  final double interestRate;
  final double cap;

  SavingsAccountType({
    required this.id,
    required this.name,
    required this.interestRate,
    required this.cap,
  });

  factory SavingsAccountType.fromJson(Map<String, dynamic> json) {
    return SavingsAccountType(
      id: json['id'],
      name: json['name'],
      interestRate: (json['interestRate'] as num).toDouble(),
      cap: (json['cap'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'interestRate': interestRate,
    'cap': cap,
  };
}