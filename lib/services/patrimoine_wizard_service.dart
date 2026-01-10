import 'package:flutter/cupertino.dart';

import '../models/bank.dart';
import '../models/patrimoine_type.dart';
import '../models/savings_account.dart';
import '../repositories/local_database_repository.dart';
import 'bank_service.dart';
import 'cash_account_service.dart';
import 'savings_account_service.dart';

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
    final bankService = BankService(db.banks);
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
        final bankService = BankService(db.banks);
        final savingsService = SavingsAccountService(db,bankService);

        // ✅ 1. Trouver le SavingsAccountType par nom
        final savingsAccountType = db.savingsAccountTypes.firstWhere(
              (sat) => sat.name == type.name,
          orElse: () => throw Exception('Type de compte épargne "${type.name}" introuvable'),
        );

        print("IIIIIIIIIIICIIIIIIIIII : "+savingsAccountType.name);

        // ✅ 2. Trouver le SavingsAccount qui correspond au type ET à la banque
        SavingsAccount? savingsAccount;
        try {
          savingsAccount = db.savingsAccounts.firstWhere(
                (sa) => sa.savingsAccountTypeId == savingsAccountType.id && sa.bankId == bank!.id,
          );
          debugPrint('✅ SavingsAccount trouvé: id=${savingsAccount.id}');
        } catch (e) {
          // ✅ 3. Si pas trouvé, créer le SavingsAccount
          final newId = db.savingsAccounts.isEmpty
              ? 1
              : db.savingsAccounts.map((sa) => sa.id).reduce((a, b) => a > b ? a : b) + 1;

          savingsAccount = SavingsAccount(
            id: newId,
            savingsAccountTypeId: savingsAccountType.id,
            bankId: bank!.id,
          );

          db.savingsAccounts.add(savingsAccount);
          debugPrint('✅ SavingsAccount créé: id=$newId, type=${savingsAccountType.name}, banque=${bank.name}');
        }

        // ✅ 4. Créer le UserSavingsAccount
        success = await savingsService.createUserSavingsAccount(
          userId: userId,
          savingsAccountId: savingsAccount.id,
          balance: balance,
          interestAccrued: 0,
        );
        break;

      case 'investmentAccount':
      // TODO: Implémenter la création de compte d'investissement
        debugPrint('⚠️ Création InvestmentAccount non implémentée');
        break;

      case 'restaurantVoucher':
      // TODO: Implémenter la création de titres restaurant
        debugPrint('⚠️ Création RestaurantVoucher non implémentée');
        break;
    }

    if (success) {
      await repo.save(db);
    }

    return success;
  }
}