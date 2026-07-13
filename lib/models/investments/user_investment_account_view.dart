class UserInvestmentAccountView {
  final int id;
  final int investmentCategoryId; // 👈 Ajouté pour la fiscalité
  final String sourceName; // PEA ou AV ou CTO
  final String bankName;
  final String logoUrl;
  final double totalContribution; // cumul des versements
  final double cashBalance; // solde espèce
  double amount; // valeur totale
  final DateTime? openedAt;

  UserInvestmentAccountView({
    required this.id,
    required this.investmentCategoryId,
    required this.sourceName,
    required this.bankName,
    required this.logoUrl,
    required this.totalContribution,
    required this.cashBalance,
    required this.amount,
    this.openedAt,
  });

  // Vérifie si c'est une Assurance Vie (pas d'espèces)
  bool get isAssuranceVie => sourceName.toLowerCase().contains('assurance');
}
