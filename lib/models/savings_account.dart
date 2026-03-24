// 📁 models/savings_account.dart (MODIFIÉ)

class SavingsAccount {
  final int id;
  final int savingsAccountTypeId; // ✅ Référence vers SavingsAccountType
  final int bankId;

  SavingsAccount({
    required this.id,
    required this.savingsAccountTypeId,
    required this.bankId,
  });

  factory SavingsAccount.fromJson(Map<String, dynamic> json) {
    return SavingsAccount(
      id: json['id'],
      savingsAccountTypeId: json['savingsAccountTypeId'],
      bankId: json['bankId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'savingsAccountTypeId': savingsAccountTypeId,
    'bankId': bankId,
  };
}
