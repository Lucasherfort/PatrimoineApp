class UserSavingsAccountView {
  final int id;
  final String sourceName;
  final String bankName;
  final String logoUrl; // 👈 Nouveau champ
  final double principal;
  final double interest;

  UserSavingsAccountView({
    required this.id,
    required this.sourceName,
    required this.bankName,
    required this.logoUrl, // 👈 Ajouté
    required this.principal,
    required this.interest,
  });
}