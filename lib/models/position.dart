class Position {
  final int id;
  final String ticker;
  final String name;
  final String currency;
  final String type;
  final double price;
  final DateTime updatedAt;

  Position({
    required this.id,
    required this.ticker,
    required this.name,
    required this.currency,
    required this.type,
    required this.price,
    required this.updatedAt,
  });

  /// Crée un objet Position à partir d'un Map (ex: réponse Supabase)
  factory Position.fromMap(Map<String, dynamic> map) {
    return Position(
      id: map['id'] as int,
      ticker: map['ticker'] as String,
      name: map['name'] as String,
      currency: map['currency'] as String,
      type: map['type'] as String,
      price: (map['price'] as num).toDouble(),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convertit l'objet en Map pour insertion ou update
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticker': ticker,
      'name': name,
      'currency': currency,
      'type': type,
      'price': price,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Position(id: $id, ticker: $ticker, name: $name, price: $price, type: $type, currency: $currency)';
  }
}