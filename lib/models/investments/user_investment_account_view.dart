class UserInvestmentAccountView {
  final int id;
  final String sourceName; // PEA ou AV ou CTO
  final String bankName;
  final String logoUrl; // 👈 Nouveau champ
  final double totalContribution; // cumul des versements
  final double cashBalance; // solde espèce
  final double amount; // valeur totale

  UserInvestmentAccountView({
    required this.id,
    required this.sourceName,
    required this.bankName,
    required this.logoUrl, // 👈 Ajouté
    required this.totalContribution,
    required this.cashBalance,
    required this.amount
  });

  // Vérifie si c'est une Assurance Vie (pas d'espèces)
  bool get isAssuranceVie => sourceName.toLowerCase().contains('assurance');
}