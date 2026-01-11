class UserInvestmentAccountView {
  final int id;
  final String sourceName; // PEA ou AV ou CTO
  final String bankName;
  final double totalContribution; // cumul des versements
  final double cashBalance; // solde espèce
  final double amount; // valeur totale

  UserInvestmentAccountView({
    required this.id,
    required this.sourceName,
    required this.bankName,
    required this.totalContribution,
    required this.cashBalance,
    required this.amount
  });
}