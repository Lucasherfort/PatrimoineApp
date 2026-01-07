import '../models/local_database.dart';
import '../models/user_restaurant_voucher.dart';
import '../repositories/local_database_repository.dart';

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
        id: urv.id,
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

  // ✅ Méthode pour mettre à jour le solde d'un voucher
  Future<bool> updateVoucherBalance(int voucherId, double newBalance) async {
    final voucherIndex = db.userRestaurantVouchers
        .indexWhere((urv) => urv.id == voucherId);

    if (voucherIndex != -1) {
      final oldVoucher = db.userRestaurantVouchers[voucherIndex];

      // ✅ Vérifie si la valeur a changé
      if (oldVoucher.balance == newBalance) {
        print('ℹ️ Voucher $voucherId: aucun changement (${newBalance} €)');
        return false; // Pas de changement
      }

      final updatedVoucher = UserRestaurantVoucher(
        id: oldVoucher.id,
        userId: oldVoucher.userId,
        restaurantVoucherId: oldVoucher.restaurantVoucherId,
        balance: newBalance,
      );

      db.userRestaurantVouchers[voucherIndex] = updatedVoucher;

      final repo = LocalDatabaseRepository();
      await repo.save(db);

      print('✅ Voucher $voucherId mis à jour: ${oldVoucher.balance} € → $newBalance €');
      return true;
    }

    return false;
  }
}

class UserRestaurantVoucherView {
  final int id;
  final double balance;
  final String voucherName;

  UserRestaurantVoucherView({
    required this.id,
    required this.balance,
    required this.voucherName,
  });
}