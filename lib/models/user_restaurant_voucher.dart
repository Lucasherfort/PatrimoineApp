class UserRestaurantVoucher {
  final int id;
  final int userId;
  final int restaurantVoucherId;
  final double balance;

  UserRestaurantVoucher({
    required this.id,
    required this.userId,
    required this.restaurantVoucherId,
    required this.balance,
  });

  factory UserRestaurantVoucher.fromJson(Map<String, dynamic> json) {
    return UserRestaurantVoucher(
      id: json['id'],
      userId: json['userId'],
      restaurantVoucherId: json['restaurantVoucherId'],
      balance: (json['balance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'restaurantVoucherId': restaurantVoucherId,
    'balance': balance,
  };
}