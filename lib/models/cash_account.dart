class CashAccount {
  final int id;
  final String name; // CCP, Compte courant, etc.
  final int bankId;

  CashAccount({
    required this.id,
    required this.name,
    required this.bankId,
  });

  factory CashAccount.fromJson(Map<String, dynamic> json) {
    return CashAccount(
      id: json['id'],
      name: json['name'],
      bankId: json['bankId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bankId': bankId,
  };
}