class UserInvestmentAccount {
  final int id;
  final int userId;
  final int investmentAccountId;
  final double cumulativeDeposits; // Cumul des versement
  final double latentCapitalGain;
  final double cashBalance; // Solde en espèce

  UserInvestmentAccount({
    required this.id,
    required this.userId,
    required this.investmentAccountId,
    required this.cumulativeDeposits,
    required this.latentCapitalGain,
    required this.cashBalance,
  });

  factory UserInvestmentAccount.fromJson(Map<String, dynamic> json) {
    return UserInvestmentAccount(
      id: json['id'],
      userId: json['userId'],
      investmentAccountId: json['investmentAccountId'],
      cumulativeDeposits: (json['cumulativeDeposits'] as num).toDouble(),
      latentCapitalGain: (json['latentCapitalGain'] as num).toDouble(),
      cashBalance: (json['cashBalance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'investmentAccountId': investmentAccountId,
    'cumulativeDeposits': cumulativeDeposits,
    'latentCapitalGain': latentCapitalGain,
    'cashBalance': cashBalance,
  };
}