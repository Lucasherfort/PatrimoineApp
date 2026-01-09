// 📁 models/bank.dart
class Bank {
  final int id;
  final String name;

  Bank({required this.id, required this.name});

  factory Bank.fromJson(Map<String, dynamic> json) =>
      Bank(id: json['id'], name: json['name']);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Bank && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// 📁 models/restaurant_voucher.dart
class RestaurantVoucher {
  final int id;
  final String name;

  RestaurantVoucher({required this.id, required this.name});

  factory RestaurantVoucher.fromJson(Map<String, dynamic> json) =>
      RestaurantVoucher(id: json['id'], name: json['name']);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is RestaurantVoucher &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}