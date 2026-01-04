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
}

class UserRestaurantVoucherView {
  final double balance;
  final String voucherName;

  UserRestaurantVoucherView({
    required this.balance,
    required this.voucherName,
  });
}