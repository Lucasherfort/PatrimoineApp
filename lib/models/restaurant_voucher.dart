class RestaurantVoucher {
  final int id;
  final String name; // Swile, Edenred, etc.

  RestaurantVoucher({
    required this.id,
    required this.name,
  });

  factory RestaurantVoucher.fromJson(Map<String, dynamic> json) {
    return RestaurantVoucher(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}