import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/bank.dart';
import '../models/patrimoine_type.dart';
import '../models/savings_account.dart';
import '../models/restaurant_voucher.dart';
import '../repositories/local_database_repository.dart';
import 'bank_service.dart';
import 'cash_account_service.dart';
import 'savings_account_service.dart';

class PatrimoineWizardService {
  final LocalDatabaseRepository repo;

  PatrimoineWizardService(this.repo);

  /// 🔹 Crée un élément de patrimoine selon son type
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
        final savingsService = SavingsAccountService(db, bankService);

        // 1️⃣ Trouver le SavingsAccountType
        final savingsAccountType = db.savingsAccountTypes.firstWhere(
              (sat) => sat.name == type.name,
          orElse: () =>
          throw Exception('Type de compte épargne "${type.name}" introuvable'),
        );

        // 2️⃣ Trouver ou créer le SavingsAccount correspondant à la banque
        SavingsAccount? savingsAccount;
        try {
          savingsAccount = db.savingsAccounts.firstWhere(
                (sa) =>
            sa.savingsAccountTypeId == savingsAccountType.id &&
                sa.bankId == bank!.id,
          );
        } catch (e) {
          final newId = db.savingsAccounts.isEmpty
              ? 1
              : db.savingsAccounts
              .map((sa) => sa.id)
              .reduce((a, b) => a > b ? a : b) +
              1;

          savingsAccount = SavingsAccount(
            id: newId,
            savingsAccountTypeId: savingsAccountType.id,
            bankId: bank!.id,
          );
          db.savingsAccounts.add(savingsAccount);
        }

        // 3️⃣ Créer le UserSavingsAccount
        success = await savingsService.createUserSavingsAccount(
          userId: userId,
          savingsAccountId: savingsAccount.id,
          balance: balance,
          interestAccrued: 0,
        );
        break;

      case 'investmentAccount':
        debugPrint('⚠️ Création InvestmentAccount non implémentée');
        break;

      case 'restaurantVoucher':
        debugPrint('⚠️ Création RestaurantVoucher non implémentée');
        break;
    }

    if (success) {
      await repo.save(db);
    }

    return success;
  }

  // ------------------------------
  // Méthodes utilitaires pour les dropdowns
  // ------------------------------

  /// 🔹 Retourne les banques disponibles pour un type de compte
  Future<List<Bank>> getAvailableBanksForType(PatrimoineType type) async {
    final db = await repo.load();
    final bankService = BankService(db.banks);

    if (type.entityType == 'savingsAccount') {
      // Filtrer les banques qui proposent le type d'épargne choisi
      final savingsType = db.savingsAccountTypes.firstWhere(
            (sat) => sat.name == type.name,
        orElse: () =>
        throw Exception('Type épargne "${type.name}" introuvable'),
      );

      final bankIds = db.savingsAccounts
          .where((sa) => sa.savingsAccountTypeId == savingsType.id)
          .map((sa) => sa.bankId)
          .toSet()
          .toList();

      return bankService.getByIds(bankIds);
    } else if (type.entityType == 'investmentAccount') {
      // Filtrer les banques qui proposent ce type d'investissement
      final bankIds = db.investmentAccounts
          .where((ia) => ia.name == type.name)
          .map((ia) => ia.bankId)
          .toSet()
          .toList();

      return bankService.getByIds(bankIds);
    } else if (type.entityType == 'cashAccount') {
      // Toutes les banques sont possibles pour un compte cash
      return db.banks;
    } else {
      return [];
    }
  }

  /// 🔹 Retourne les plateformes disponibles pour les titres restaurant
  Future<List<RestaurantVoucher>> getAvailableVouchers() async {
    final db = await repo.load();
    return db.restaurantVouchers;
  }
}
