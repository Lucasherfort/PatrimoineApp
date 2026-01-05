import '../models/local_database.dart';

class RestaurantVoucherService {
  final LocalDatabase db;

  RestaurantVoucherService(this.db);

  List<UserRestaurantVoucherView> getVouchersForUser(int userId) {
    final userVouchers = db.userRestaurantVouchers
        .where((urv) => urv.userId == userId)
        .toList();

    return userVouchers.map((urv) {
      final voucher = db.restaurantVouchers
          .firstWhere((rv) => rv.id == urv.restaurantVoucherId);

      return UserRestaurantVoucherView(
        balance: urv.balance,
        voucherName: voucher.name,
      );
    }).toList();
  }

  double getTotalVouchersForUser(int userId) {
    return db.userRestaurantVouchers
        .where((urv) => urv.userId == userId)
        .fold(0.0, (total, voucher) => total + voucher.balance);
  }

  void updateVoucherBalance({
    required int userId,
    required String voucherName,
    required double newBalance,
  }) {
    final voucher = db.restaurantVouchers
        .firstWhere((v) => v.name == voucherName);

    final userVoucher = db.userRestaurantVouchers.firstWhere(
          (urv) =>
      urv.userId == userId &&
          urv.restaurantVoucherId == voucher.id,
    );

    userVoucher.balance = newBalance;
  }
}

class UserRestaurantVoucherView {
  final double balance;
  final String voucherName;

  UserRestaurantVoucherView({
    required this.balance,
    required this.voucherName,
  });
}