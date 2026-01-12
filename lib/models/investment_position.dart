class InvestmentPosition {
  final int id;
  final int userInvestmentAccountId;
  final String ticker;
  String? name; // Récupéré depuis Google Sheet
  final String supportType ;
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
      currentPrice = double.tryParse(priceValue.replaceAll(',', '.').replaceAll(' ', ''));
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
}