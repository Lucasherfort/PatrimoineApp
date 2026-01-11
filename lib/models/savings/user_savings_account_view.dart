class UserSavingsAccountView {
  final int id;
  final String sourceName;
  final String bankName;
  final double principal;
  final double interest;

  UserSavingsAccountView({
    required this.id,
    required this.sourceName,
    required this.bankName,
    required this.principal,
    required this.interest
  });
}