class InvestmentPosition {
  final int id;
  final int userInvestmentAccountId;
  final String ticker;
  String? name; // Récupéré depuis Google Sheet
  final String supportType ;
  final double quantity;
  final double pru;
  double? currentPrice;


  InvestmentPosition({
    required this.id,
    required this.userInvestmentAccountId,
    required this.ticker,
    this.name,
    required this.supportType,
    required this.quantity,
    required this.pru,
    this.currentPrice
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

    if (sheetData['price'] != null) {
      final priceValue = sheetData['price'].toString();
      currentPrice = double.tryParse(priceValue.replaceAll(',', '.').replaceAll(' ', ''));
    }
  }
}