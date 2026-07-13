class UserInvestmentAccount {
  final int id;
  final String userId; // UUID
  final int? investmentSourceId;

  double cumulativeDeposits; // total_contribution
  double cashBalance; // cash_balance
  double amount; // amount (valeur totale si tu l’utilises)
  DateTime? openedAt;

  UserInvestmentAccount({
    required this.id,
    required this.userId,
    required this.cumulativeDeposits,
    required this.cashBalance,
    required this.amount,
    this.investmentSourceId,
    this.openedAt,
  });

  factory UserInvestmentAccount.fromMap(Map<String, dynamic> map) {
    return UserInvestmentAccount(
      id: map['id'] as int,
      userId: map['user_id'] as String,
      cumulativeDeposits:
          (map['total_contribution'] as num?)?.toDouble() ?? 0.0,
      cashBalance: (map['cash_balance'] as num?)?.toDouble() ?? 0.0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      investmentSourceId: map['investment_source_id'] as int?,
      openedAt: map['opened_at'] != null
          ? DateTime.tryParse(map['opened_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'total_contribution': cumulativeDeposits,
    'cash_balance': cashBalance,
    'amount': amount,
    'investment_source_id': investmentSourceId,
    'opened_at': openedAt?.toIso8601String(),
  };
}
