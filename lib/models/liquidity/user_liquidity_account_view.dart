class UserLiquidityAccountView {
  final int id;
  final String sourceName;
  final String bankName;
  final String logoUrl; // 👈 Nouveau champ
  final double amount;

  UserLiquidityAccountView({
    required this.id,
    required this.sourceName,
    required this.bankName,
    required this.logoUrl, // 👈 Ajouté
    required this.amount,
  });
}