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

  UserInvestmentAccountView copyWith({
    int? id,
    int? investmentCategoryId,
    String? sourceName,
    String? bankName,
    String? logoUrl,
    double? totalContribution,
    double? cashBalance,
    double? amount,
    DateTime? openedAt,
  }) {
    return UserInvestmentAccountView(
      id: id ?? this.id,
      investmentCategoryId: investmentCategoryId ?? this.investmentCategoryId,
      sourceName: sourceName ?? this.sourceName,
      bankName: bankName ?? this.bankName,
      logoUrl: logoUrl ?? this.logoUrl,
      totalContribution: totalContribution ?? this.totalContribution,
      cashBalance: cashBalance ?? this.cashBalance,
      amount: amount ?? this.amount,
      openedAt: openedAt ?? this.openedAt,
    );
  }
}
