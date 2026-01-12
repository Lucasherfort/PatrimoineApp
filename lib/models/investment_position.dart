class InvestmentPosition {
  final int id;
  final int userInvestmentAccountId;
  final String ticker;
  String? name; // Récupéré depuis Google Sheet
  final String supportType;
  final double quantity;
  final double pru;
  double? currentPrice;

  // Nouvelles infos depuis Google Sheet
  String? currency;
  double? priceOpen;
  double? high;
  double? low;
  int? volume;

  InvestmentPosition({
    required this.id,
    required this.userInvestmentAccountId,
    required this.ticker,
    this.name,
    required this.supportType,
    required this.quantity,
    required this.pru,
    this.currentPrice,
    this.currency,
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
  double get performance =>
      ((totalValue / (pru * quantity)) - 1) * 100;

  // Méthode pour mettre à jour avec les données du Google Sheet
  void updateFromSheet(Map<String, dynamic> sheetData) {
    name = sheetData['name']?.toString() ?? name;
    currency = sheetData['currency']?.toString();

    if (sheetData['price'] != null) {
      final priceValue = sheetData['price'].toString();
      currentPrice =
          double.tryParse(priceValue.replaceAll(',', '.').replaceAll(' ', ''));
    }

    if (sheetData['priceopen'] != null) {
      final value = sheetData['priceopen'].toString();
      priceOpen = double.tryParse(value.replaceAll(',', '.').replaceAll(' ', ''));
    }
    if (sheetData['high'] != null) {
      final value = sheetData['high'].toString();
      high = double.tryParse(value.replaceAll(',', '.').replaceAll(' ', ''));
    }
    if (sheetData['low'] != null) {
      final value = sheetData['low'].toString();
      low = double.tryParse(value.replaceAll(',', '.').replaceAll(' ', ''));
    }
    if (sheetData['volume'] != null) {
      final value = sheetData['volume'].toString();
      volume = int.tryParse(value.replaceAll(',', '').replaceAll(' ', ''));
    }
  }

  // ✅ Nouvelle méthode fromMap pour créer l'objet depuis la BDD / Supabase
  factory InvestmentPosition.fromMap(Map<String, dynamic> map) {
    return InvestmentPosition(
      id: map['id'] as int,
      userInvestmentAccountId: map['user_investment_account_id'] as int,
      ticker: map['ticker']?.toString() ?? '',
      name: map['name']?.toString(),
      supportType: map['position_category_id']?.toString() ?? 'unknown',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      pru: (map['pru'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (map['current_price'] as num?)?.toDouble(),
    );
  }

  // Optionnel : toMap pour l'insert / update
  Map<String, dynamic> toMap() => {
    'id': id,
    'user_investment_account_id': userInvestmentAccountId,
    'ticker': ticker,
    'name': name,
    'position_category_id': supportType,
    'quantity': quantity,
    'pru': pru,
    'current_price': currentPrice,
  };
}