class UserInvestmentAccount {
  final int id;
  final int userId;
  final int investmentAccountId;
  final double balance;
  final double latentCapitalGain;

  UserInvestmentAccount({
    required this.id,
    required this.userId,
    required this.investmentAccountId,
    required this.balance,
    required this.latentCapitalGain,
  });

  factory UserInvestmentAccount.fromJson(Map<String, dynamic> json) =>
      UserInvestmentAccount(
        id: json['id'],
        userId: json['userId'],
        investmentAccountId: json['investmentAccountId'],
        balance: (json['balance'] as num).toDouble(),
        latentCapitalGain: (json['latentCapitalGain'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'investmentAccountId': investmentAccountId,
    'balance': balance,
    'latentCapitalGain': latentCapitalGain,
  };
}