class InvestmentPosition {
  final int id;
  final int userInvestmentAccountId;
  final String ticker; // Ex: "CW8", "PAEEM"
  final String name; // Ex: "MSCI World", "Amundi MSCI EM"
  final String type; // "ETF", "Action", "Obligation", "Fonds"
  final String? isinCode; // Code ISIN pour récupérer le cours
  final int quantity;
  final double averagePurchasePrice; // PRU (Prix de Revient Unitaire)
  final double? currentPrice; // Prix actuel (peut être null avant scraping)

  InvestmentPosition({
    required this.id,
    required this.userInvestmentAccountId,
    required this.ticker,
    required this.name,
    required this.type,
    this.isinCode,
    required this.quantity,
    required this.averagePurchasePrice,
    this.currentPrice,
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
        isinCode: json['isinCode'],
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
    'isinCode': isinCode,
    'quantity': quantity,
    'averagePurchasePrice': averagePurchasePrice,
    'currentPrice': currentPrice,
  };
}