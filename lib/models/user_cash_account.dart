class UserCashAccount {
  final int id;
  final int userId;
  final int cashAccountId;
  final double balance;

  UserCashAccount({
    required this.id,
    required this.userId,
    required this.cashAccountId,
    required this.balance,
  });

  factory UserCashAccount.fromJson(Map<String, dynamic> json) {
    return UserCashAccount(
      id: json['id'],
      userId: json['userId'],
      cashAccountId: json['cashAccountId'],
      balance: (json['balance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'cashAccountId': cashAccountId,
    'balance': balance,
  };
}