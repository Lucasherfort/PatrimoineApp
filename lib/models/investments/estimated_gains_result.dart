class EstimatedGainsResult {
  final double totalGains;
  final int totalAccounts;
  final int calculableAccounts;
  final bool hasRecentAccounts;
  final bool hasMissingDates;

  EstimatedGainsResult({
    required this.totalGains,
    required this.totalAccounts,
    required this.calculableAccounts,
    required this.hasRecentAccounts,
    required this.hasMissingDates,
  });

  bool get isReliable => calculableAccounts > 0;
  bool get hasDataIssues => hasRecentAccounts || hasMissingDates;
}
