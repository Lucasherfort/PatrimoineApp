class ApplicationFiscality {
  final int id;
  final int investmentCategoryId;
  final int minHoldingYears;
  final int? maxHoldingYears;
  final double incomeTaxRate;
  final double socialContributionRate;

  ApplicationFiscality({
    required this.id,
    required this.investmentCategoryId,
    required this.minHoldingYears,
    this.maxHoldingYears,
    required this.incomeTaxRate,
    required this.socialContributionRate,
  });

  factory ApplicationFiscality.fromMap(Map<String, dynamic> map) {
    return ApplicationFiscality(
      id: map['id'] as int,
      investmentCategoryId: map['investment_category_id'] as int,
      minHoldingYears: map['min_holding_years'] as int,
      maxHoldingYears: map['max_holding_years'] as int?,
      incomeTaxRate: (map['income_tax_rate'] as num).toDouble(),
      socialContributionRate: (map['social_contribution_rate'] as num)
          .toDouble(),
    );
  }

  double get totalTaxRate => incomeTaxRate + socialContributionRate;
}
