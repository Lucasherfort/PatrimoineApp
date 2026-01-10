// 📁 models/user_savings_account.dart (INCHANGÉ)

class UserSavingsAccount {
  final int id;
  final int userId;
  final int savingsAccountId;
  double balance;
  double interestAccrued;

  UserSavingsAccount({
    required this.id,
    required this.userId,
    required this.savingsAccountId,
    required this.balance,
    required this.interestAccrued,
  });

  factory UserSavingsAccount.fromJson(Map<String, dynamic> json) {
    return UserSavingsAccount(
      id: json['id'],
      userId: json['userId'],
      savingsAccountId: json['savingsAccountId'],
      balance: (json['balance'] as num).toDouble(),
      interestAccrued: (json['interestAccrued'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'savingsAccountId': savingsAccountId,
    'balance': balance,
    'interestAccrued': interestAccrued,
  };
}