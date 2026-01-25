class InvestmentPosition {
  final int id;
  final int userInvestmentAccountId;

  /// Type du support (ex: ETF, ACTION, CRYPTO…)
  final String supportType;

  /// Infos venant de la table positions
  final int positionId;
  final String ticker;
  final String name;
  final double currentPrice;

  /// Infos propres à la position utilisateur
  final double quantity;
  final double pru;

  InvestmentPosition({
    required this.id,
    required this.userInvestmentAccountId,
    required this.supportType,
    required this.positionId,
    required this.ticker,
    required this.name,
    required this.quantity,
    required this.pru,
    required this.currentPrice,
  });

  /// Valeur totale de la position
  double get totalValue => currentPrice * quantity;

  /// Plus-value latente
  double get latentGain => totalValue - (pru * quantity);

  /// Performance en %
  double get performance {
    if (pru == 0 || quantity == 0) return 0;
    return ((currentPrice / pru) - 1) * 100;
  }

  factory InvestmentPosition.fromMap(Map<String, dynamic> map) {
    final position = map['positions'] as Map<String, dynamic>?;

    if (position == null) {
      throw Exception('Jointure positions manquante');
    }

    return InvestmentPosition(
      id: map['id'] as int,
      userInvestmentAccountId: map['user_investment_account_id'] as int,
      quantity: (map['quantity'] as num).toDouble(),
      pru: (map['pru'] as num).toDouble(),

      // Données jointes depuis `positions`
      supportType: position['type'] as String,
      positionId: position['id'] as int,
      ticker: position['ticker'] as String,
      name: position['name'] as String,
      currentPrice: (position['price'] as num).toDouble(),
    );
  }
}