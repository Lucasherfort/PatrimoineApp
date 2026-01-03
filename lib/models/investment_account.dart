class InvestmentAccount {
  final int id;
  final String name; // PEA, Assurance vie, CTO, etc.
  final int cap; // Plafond du compte
  final int bankId;

  InvestmentAccount({
    required this.id,
    required this.name,
    required this.cap,
    required this.bankId,
  });

  factory InvestmentAccount.fromJson(Map<String, dynamic> json) =>
      InvestmentAccount(
        id: json['id'],
        name: json['name'],
        cap: json['cap'],
        bankId: json['bankId'],
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cap': cap,
    'bankId': bankId,
  };
}