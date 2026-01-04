class InvestmentPosition {
  final int id;
  final int userInvestmentAccountId;
  final String ticker;
  String? name; // Peut être mis à jour depuis le sheet
  final String type;
  final int quantity;
  final double averagePurchasePrice;
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
    required this.type,
    required this.quantity,
    required this.averagePurchasePrice,
    this.currentPrice,
    this.currency,
    this.priceOpen,
    this.high,
    this.low,
    this.volume,
  });

  // Valeur totale de la position
  double get totalValue => (currentPrice ?? averagePurchasePrice) * quantity;

  // Plus-value latente
  double get latentGain => totalValue - (averagePurchasePrice * quantity);

  // Performance en %
  double get performance =>
      ((totalValue / (averagePurchasePrice * quantity)) - 1) * 100;

  factory InvestmentPosition.fromJson(Map<String, dynamic> json) =>
      InvestmentPosition(
        id: json['id'],
        userInvestmentAccountId: json['userInvestmentAccountId'],
        ticker: json['ticker'],
        name: json['name'],
        type: json['type'],
        quantity: json['quantity'],
        averagePurchasePrice: (json['averagePurchasePrice'] as num).toDouble(),
        currentPrice: json['currentPrice'] != null
            ? (json['currentPrice'] as num).toDouble()
            : null,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userInvestmentAccountId': userInvestmentAccountId,
    'ticker': ticker,
    'name': name,
    'type': type,
    'quantity': quantity,
    'averagePurchasePrice': averagePurchasePrice,
    'currentPrice': currentPrice,
  };

  // Méthode pour mettre à jour avec les données du Google Sheet
  void updateFromSheet(Map<String, dynamic> sheetData)
  {
    name = sheetData['name']?.toString() ?? name;
    currency = sheetData['currency']?.toString();

    if (sheetData['price'] != null) {
      final priceValue = sheetData['price'].toString();

      // ✅ CORRECTION: Remplace la virgule par un point AVANT de parser
      currentPrice = double.tryParse(priceValue.replaceAll(',', '.').replaceAll(' ', ''));
    }

    if (sheetData['priceopen'] != null)
    {
      final value = sheetData['priceopen'].toString();
      priceOpen = double.tryParse(value.replaceAll(',', '.').replaceAll(' ', ''));
    }
    if (sheetData['high'] != null)
    {
      final value = sheetData['high'].toString();
      high = double.tryParse(value.replaceAll(',', '.').replaceAll(' ', ''));
    }
    if (sheetData['low'] != null)
    {
      final value = sheetData['low'].toString();
      low = double.tryParse(value.replaceAll(',', '.').replaceAll(' ', ''));
    }
    if (sheetData['volume'] != null)
    {
      final value = sheetData['volume'].toString();
      volume = int.tryParse(value.replaceAll(',', '').replaceAll(' ', ''));
    }
  }
}