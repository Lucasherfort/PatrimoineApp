import 'package:flutter/cupertino.dart';

import '../models/bank.dart';
import '../models/patrimoine_type.dart';
import '../repositories/local_database_repository.dart';
import 'cash_account_service.dart';

class PatrimoineWizardService {
  final LocalDatabaseRepository repo;

  PatrimoineWizardService(this.repo);

  Future<bool> createPatrimoine({
    required PatrimoineType type,
    Bank? bank,
    RestaurantVoucher? voucher,
    required double balance,
    required int userId,
  }) async {
    final db = await repo.load();
    bool success = false;

    switch (type.entityType) {
      case 'cashAccount':
        final cashService = CashAccountService(db);
        success = await cashService.createUserCashAccount(
          userId: userId,
          bankId: bank!.id,
          initialBalance: balance,
        );
        break;
      case 'savingsAccount':
      case 'investmentAccount':
      case 'restaurantVoucher':
        debugPrint('⚠️ Création pour $type non implémentée');
        break;
    }

    if (success) {
      await repo.save(db);
    }

    return success;
  }
}