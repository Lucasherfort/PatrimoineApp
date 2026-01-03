class SavingsAccount {
  final int id;
  final String name;
  final double interestRate;
  final int cap;
  final int bankId;

  SavingsAccount({
    required this.id,
    required this.name,
    required this.interestRate,
    required this.cap,
    required this.bankId,
  });

  factory SavingsAccount.fromJson(Map<String, dynamic> json) {
    return SavingsAccount(
      id: json['id'],
      name: json['name'],
      interestRate: (json['interestRate'] as num).toDouble(),
      cap: json['cap'],
      bankId: json['bankId'],
    );
  }

  /// ✅ AJOUTER CECI
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'interestRate': interestRate,
    'cap': cap,
    'bankId': bankId,
  };
}