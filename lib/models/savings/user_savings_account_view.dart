class UserSavingsAccountView {
  final int id;
  final String sourceName;
  final String bankName;
  final String logoUrl;
  double principal;
  double interest;
  double? interestRate;
  final double? ceiling;
  DateTime? openedAt;

  UserSavingsAccountView({
    required this.id,
    required this.sourceName,
    required this.bankName,
    required this.logoUrl,
    required this.principal,
    required this.interest,
    this.interestRate,
    this.ceiling,
    this.openedAt,
  });
}
