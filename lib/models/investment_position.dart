// lib/models/investment_position.dart
class InvestmentPosition {
  final int id;
  final int userInvestmentAccountId;
  final String ticker;
  final int? positionCategoryId;
  final double quantity;
  final double pru; // Prix de Revient Unitaire
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Infos de marché (non stockées en BDD, chargées depuis API)
  String? name;
  String? currency;
  double? currentPrice;
  double? priceOpen;
  double? high;
  double? low;
  int? volume;

  InvestmentPosition({
    required this.id,
    required this.userInvestmentAccountId,
    required this.ticker,
    this.positionCategoryId,
    required this.quantity,
    required this.pru,
    this.createdAt,
    this.updatedAt,
    this.name,
    this.currency,
    this.currentPrice,
    this.priceOpen,
    this.high,
    this.low,
    this.volume,
  });

  // Valeur totale de la position
  double get totalValue => (currentPrice ?? pru) * quantity;

  // Plus-value latente
  double get latentGain => totalValue - (pru * quantity);

  // Performance en %
  double get performance {
    final invested = pru * quantity;
    if (invested == 0) return 0;
    return ((totalValue / invested) - 1) * 100;
  }

  // Variation du jour (si on a priceOpen)
  double? get dailyChange {
    if (currentPrice == null || priceOpen == null) return null;
    return currentPrice! - priceOpen!;
  }

  double? get dailyChangePercent {
    if (currentPrice == null || priceOpen == null || priceOpen == 0) return null;
    return ((currentPrice! / priceOpen!) - 1) * 100;
  }

  factory InvestmentPosition.fromDatabase(Map<String, dynamic> row) {
    return InvestmentPosition(
      id: row['id'] as int,
      userInvestmentAccountId: row['user_investment_account_id'] as int,
      ticker: row['ticker'] as String,
      positionCategoryId: row['position_category_id'] as int?,
      quantity: (row['quantity'] as num).toDouble(),
      pru: (row['pru'] as num).toDouble(),
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toDatabase() => {
    'user_investment_account_id': userInvestmentAccountId,
    'ticker': ticker,
    'position_category_id': positionCategoryId,
    'quantity': quantity,
    'pru': pru,
  };

  // Créer une copie avec les données de marché mises à jour
  InvestmentPosition copyWithMarketData({
    String? name,
    String? currency,
    double? currentPrice,
    double? priceOpen,
    double? high,
    double? low,
    int? volume,
  }) {
    return InvestmentPosition(
      id: id,
      userInvestmentAccountId: userInvestmentAccountId,
      ticker: ticker,
      positionCategoryId: positionCategoryId,
      quantity: quantity,
      pru: pru,
      createdAt: createdAt,
      updatedAt: updatedAt,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      currentPrice: currentPrice ?? this.currentPrice,
      priceOpen: priceOpen ?? this.priceOpen,
      high: high ?? this.high,
      low: low ?? this.low,
      volume: volume ?? this.volume,
    );
  }

  // Méthode pour mettre à jour avec les données du Google Sheet
  InvestmentPosition updateFromSheet(Map<String, dynamic> sheetData) {
    String? updatedName = sheetData['name']?.toString() ?? name;
    String? updatedCurrency = sheetData['currency']?.toString() ?? currency;

    double? updatedCurrentPrice = currentPrice;
    if (sheetData['price'] != null) {
      final priceValue = sheetData['price'].toString();
      updatedCurrentPrice = double.tryParse(
          priceValue.replaceAll(',', '.').replaceAll(' ', '')
      );
    }

    double? updatedPriceOpen = priceOpen;
    if (sheetData['priceopen'] != null) {
      final value = sheetData['priceopen'].toString();
      updatedPriceOpen = double.tryParse(
          value.replaceAll(',', '.').replaceAll(' ', '')
      );
    }

    double? updatedHigh = high;
    if (sheetData['high'] != null) {
      final value = sheetData['high'].toString();
      updatedHigh = double.tryParse(
          value.replaceAll(',', '.').replaceAll(' ', '')
      );
    }

    double? updatedLow = low;
    if (sheetData['low'] != null) {
      final value = sheetData['low'].toString();
      updatedLow = double.tryParse(
          value.replaceAll(',', '.').replaceAll(' ', '')
      );
    }

    int? updatedVolume = volume;
    if (sheetData['volume'] != null) {
      final value = sheetData['volume'].toString();
      updatedVolume = int.tryParse(
          value.replaceAll(',', '').replaceAll(' ', '')
      );
    }

    return copyWithMarketData(
      name: updatedName,
      currency: updatedCurrency,
      currentPrice: updatedCurrentPrice,
      priceOpen: updatedPriceOpen,
      high: updatedHigh,
      low: updatedLow,
      volume: updatedVolume,
    );
  }
}