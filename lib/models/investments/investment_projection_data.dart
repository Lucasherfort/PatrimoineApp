class InvestmentProjectionPoint {
  final int year;
  final double savingsEffort; // Total out of pocket
  final double totalInterests; // Cumulative gains (PnL + interests)
  final double totalBalance; // Savings + Interests

  InvestmentProjectionPoint({
    required this.year,
    required this.savingsEffort,
    required this.totalInterests,
    required this.totalBalance,
  });
}
