class UserSavingsAccountView {
  final int id;
  final String sourceName;
  final String bankName;
  final String logoUrl;
  double principal;
  double interest;
  final double? interestRate; // 👈 Nouveau (nullable)
  final double? ceiling;      // 👈 Nouveau (nullable)

  UserSavingsAccountView({
    required this.id,
    required this.sourceName,
    required this.bankName,
    required this.logoUrl,
    required this.principal,
    required this.interest,
    this.interestRate,  // 👈 Optionnel
    this.ceiling,       // 👈 Optionnel
  });
}
