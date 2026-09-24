class UserLiquidityAccountView {
  final int id;
  final String sourceName;
  final String bankName;
  final String logoUrl;
  double amount;

  UserLiquidityAccountView({
    required this.id,
    required this.sourceName,
    required this.bankName,
    required this.logoUrl,
    required this.amount,
  });
}
