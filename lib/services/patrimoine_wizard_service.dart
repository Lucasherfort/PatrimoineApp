import '../models/bank.dart';
import '../models/investment_account.dart';
import '../models/patrimoine_type.dart';
import '../models/savings_account.dart';
import '../models/restaurant_voucher.dart';
import '../models/user_investment_account.dart';
import '../models/user_restaurant_voucher.dart';
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
      // 1️⃣ Trouver l'InvestmentAccount correspondant au type choisi
        InvestmentAccount investmentAccount;
        try {
          investmentAccount = db.investmentAccounts.firstWhere(
                (ia) => ia.name == type.name,
          );
        } catch (e) {
          throw Exception('InvestmentAccount "${type.name}" introuvable');
        }

        // 2️⃣ Vérifier si l'utilisateur possède déjà ce compte
        bool exists = db.userInvestmentAccounts.any(
                (uia) => uia.userId == userId && uia.investmentAccountId == investmentAccount.id
        );

        if (exists) {
          throw Exception('L\'utilisateur possède déjà un compte d\'investissement "${type.name}"');
        }

        // 3️⃣ Créer le UserInvestmentAccount
        final newId = db.userInvestmentAccounts.isEmpty
            ? 1
            : db.userInvestmentAccounts.map((uia) => uia.id).reduce((a, b) => a > b ? a : b) + 1;

        final userInvestmentAccount = UserInvestmentAccount(
          id: newId,
          userId: userId,
          investmentAccountId: investmentAccount.id,
          cumulativeDeposits: 0.0,
          latentCapitalGain: 0.0,
          cashBalance: 0.0,
        );

        db.userInvestmentAccounts.add(userInvestmentAccount);

        success = true;
        break;

      case 'restaurantVoucher':
        if (voucher == null) {
          throw Exception('Aucune plateforme sélectionnée pour le titre restaurant');
        }

        // Vérifier si l'utilisateur possède déjà ce voucher
        bool exists = db.userRestaurantVouchers.any(
                (urv) => urv.userId == userId && urv.restaurantVoucherId == voucher.id
        );

        if (exists) {
          throw Exception(
              'L\'utilisateur possède déjà un titre restaurant "${voucher.name}"');
        }

        // Créer le UserRestaurantVoucher
        final newId = db.userRestaurantVouchers.isEmpty
            ? 1
            : db.userRestaurantVouchers.map((urv) => urv.id).reduce((a, b) => a > b ? a : b) + 1;

        final userVoucher = UserRestaurantVoucher(
          id: newId,
          userId: userId,
          restaurantVoucherId: voucher.id,
          balance: 0.0, // Toujours 0 par défaut
        );

        db.userRestaurantVouchers.add(userVoucher);
        success = true;
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
      final bankIds = db.investmentAccounts
          .where((ia) => ia.name == type.name)
          .map((ia) => ia.bankId)
          .toSet()
          .toList();

      return bankService.getByIds(bankIds);
    } else if (type.entityType == 'cashAccount') {
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
