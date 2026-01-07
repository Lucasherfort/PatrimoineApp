import '../models/local_database.dart';
import '../models/user_cash_account.dart';
import '../models/cash_account.dart';
import '../models/bank.dart';
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

  // ✅ Méthode pour mettre à jour le solde d'un compte espèces
  Future<bool> updateCashAccountBalance(int accountId, double newBalance) async {
    final accountIndex = db.userCashAccounts
        .indexWhere((uca) => uca.id == accountId);

    if (accountIndex != -1) {
      final oldAccount = db.userCashAccounts[accountIndex];

      // ✅ Vérifie si la valeur a changé
      if (oldAccount.balance == newBalance) {
        print('ℹ️ Compte espèces $accountId: aucun changement (${newBalance} €)');
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

      print('✅ Compte espèces $accountId mis à jour: ${oldAccount.balance} € → $newBalance €');
      return true;
    }

    return false;
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