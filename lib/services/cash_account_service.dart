import '../models/cash_account.dart';
import '../models/local_database.dart';
import '../models/user_cash_account.dart';
import '../repositories/local_database_repository.dart';

class CashAccountService {
  final LocalDatabase db;

  CashAccountService(this.db);

  List<UserCashAccountView> getAccountsForUser(int userId) {
    final userAccounts = db.userCashAccounts
        .where((uca) => uca.userId == userId)
        .toList();

    return userAccounts.map((uca) {
      final account = db.cashAccounts
          .firstWhere((ca) => ca.id == uca.cashAccountId);
      final bank = db.banks.firstWhere((b) => b.id == account.bankId);

      return UserCashAccountView(
        id: uca.id,
        balance: uca.balance,
        cashAccountName: account.name,
        bankName: bank.name,
      );
    }).toList();
  }

  double getTotalCashForUser(int userId) {
    return db.userCashAccounts
        .where((uca) => uca.userId == userId)
        .fold(0.0, (total, account) => total + account.balance);
  }

  Future<bool> deleteCashAccount(int accountId) async {
    final index =
    db.userCashAccounts.indexWhere((uca) => uca.id == accountId);
    if (index != -1) {
      db.userCashAccounts.removeAt(index);
      await LocalDatabaseRepository().save(db);
      return true;
    }
    return false;
  }
  // ✅ Méthode pour mettre à jour le solde d'un compte espèces
  Future<bool> updateCashAccountBalance(int accountId, double newBalance) async {
    final accountIndex = db.userCashAccounts
        .indexWhere((uca) => uca.id == accountId);

    if (accountIndex != -1) {
      final oldAccount = db.userCashAccounts[accountIndex];

      // ✅ Vérifie si la valeur a changé
      if (oldAccount.balance == newBalance)
      {
        return false; // Pas de changement
      }

      final updatedAccount = UserCashAccount(
        id: oldAccount.id,
        userId: oldAccount.userId,
        cashAccountId: oldAccount.cashAccountId,
        balance: newBalance,
      );

      db.userCashAccounts[accountIndex] = updatedAccount;

      final repo = LocalDatabaseRepository();
      await repo.save(db);
      return true;
    }

    return false;
  }

  /// Crée un nouveau compte espèces pour un utilisateur
  Future<bool> createUserCashAccount({
    required int userId,
    required int bankId,
    required double initialBalance,
  }) async {
    try {
      // 1️⃣ Vérifier si un CashAccount existe pour cette banque
      CashAccount? cashAccount;
      try {
        cashAccount = db.cashAccounts.firstWhere(
              (ca) => ca.bankId == bankId,
        );
      } catch (e) {
        // 2️⃣ Si le CashAccount n'existe pas, le créer
        final newCashAccountId = db.cashAccounts.isEmpty
            ? 1
            : db.cashAccounts.map((ca) => ca.id).reduce((a, b) => a > b ? a : b) + 1;

        cashAccount = CashAccount(
          id: newCashAccountId,
          name: 'Compte espèces',
          bankId: bankId,
        );

        db.cashAccounts.add(cashAccount);
      }

      // 3️⃣ Créer le UserCashAccount
      final newUserCashAccountId = db.userCashAccounts.isEmpty
          ? 1
          : db.userCashAccounts.map((uca) => uca.id).reduce((a, b) => a > b ? a : b) + 1;

      final newUserCashAccount = UserCashAccount(
        id: newUserCashAccountId,
        userId: userId,
        cashAccountId: cashAccount.id,
        balance: initialBalance,
      );

      db.userCashAccounts.add(newUserCashAccount);

      // 4️⃣ Sauvegarder dans le JSON
      final repo = LocalDatabaseRepository();
      await repo.save(db);

      return true;
    }
    catch (e)
    {
      return false;
    }
  }

}

class UserCashAccountView {
  final int id;
  final double balance;
  final String cashAccountName;
  final String bankName;

  UserCashAccountView({
    required this.id,
    required this.balance,
    required this.cashAccountName,
    required this.bankName,
  });
}