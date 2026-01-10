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
      if (oldVoucher.balance == newBalance)
      {
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

      return true;
    }

    return false;
  }

  /// Supprime un titre restaurant d'un utilisateur
  Future<bool> deleteUserVoucher(int voucherId) async {
    final index = db.userRestaurantVouchers.indexWhere((urv) => urv.id == voucherId);

    if (index == -1) return false;

    db.userRestaurantVouchers.removeAt(index);

    final repo = LocalDatabaseRepository();
    await repo.save(db);

    return true;
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