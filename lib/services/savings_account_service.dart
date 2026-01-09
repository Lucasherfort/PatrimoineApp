import '../models/local_database.dart';
import '../models/user_savings_account.dart';
import '../repositories/local_database_repository.dart';

class SavingsAccountService {
  final LocalDatabase db;

  SavingsAccountService(this.db);

  List<UserSavingsAccountView> getAccountsForUser(int userId) {
    final accounts = db.userSavingsAccounts
        .where((usa) => usa.userId == userId)
        .toList();

    return accounts.map((usa) {
      final account = db.savingsAccounts
          .firstWhere((a) => a.id == usa.savingsAccountId);
      final bank = db.banks.firstWhere((b) => b.id == account.bankId);

      return UserSavingsAccountView(
        id: usa.id,
        balance: usa.balance,
        interestAccrued: usa.interestAccrued,
        savingsAccountName: account.name,
        bankName: bank.name,
        cap: account.cap,
      );
    }).toList();
  }

  double getTotalSavingsForUser(int userId) {
    return db.userSavingsAccounts
        .where((usa) => usa.userId == userId)
        .fold(0.0, (total, account) => total + account.balance + account.interestAccrued);
  }

  Future<SavingsAccountUpdateResult> updateSavingsAccount(
      int accountId,
      double newBalance,
      double newInterest
      ) async {
    final accountIndex = db.userSavingsAccounts
        .indexWhere((usa) => usa.id == accountId);

    if (accountIndex == -1) {
      return SavingsAccountUpdateResult(
        success: false,
        error: 'Compte non trouvé',
      );
    }

    final oldAccount = db.userSavingsAccounts[accountIndex];

    if (oldAccount.balance == newBalance && oldAccount.interestAccrued == newInterest) {
      return SavingsAccountUpdateResult(success: false);
    }

    final savingsAccount = db.savingsAccounts
        .firstWhere((sa) => sa.id == oldAccount.savingsAccountId);

    if (newBalance > savingsAccount.cap) {
      return SavingsAccountUpdateResult(
        success: false,
        error: 'Le solde (${newBalance.toStringAsFixed(2)} €) dépasse le plafond de ${savingsAccount.cap} € pour ${savingsAccount.name}',
      );
    }

    final updatedAccount = UserSavingsAccount(
      id: oldAccount.id,
      userId: oldAccount.userId,
      savingsAccountId: oldAccount.savingsAccountId,
      balance: newBalance,
      interestAccrued: newInterest,
    );

    db.userSavingsAccounts[accountIndex] = updatedAccount;

    final repo = LocalDatabaseRepository();
    await repo.save(db);

    return SavingsAccountUpdateResult(success: true);
  }

  // -------------------------------
  // 🗑️ SUPPRESSION D'UN COMPTE
  // -------------------------------
  Future<bool> deleteSavingsAccount(int userSavingsAccountId) async {
    final index = db.userSavingsAccounts.indexWhere((u) => u.id == userSavingsAccountId);
    if (index == -1) return false;

    db.userSavingsAccounts.removeAt(index);

    final repo = LocalDatabaseRepository();
    await repo.save(db);

    return true;
  }
}

// ✅ Classe pour le résultat de la mise à jour
class SavingsAccountUpdateResult {
  final bool success;
  final String? error;

  SavingsAccountUpdateResult({
    required this.success,
    this.error,
  });
}

class UserSavingsAccountView {
  final int id;
  final double balance;
  final double interestAccrued;
  final String savingsAccountName;
  final String bankName;
  final int cap; // ✅ Ajout du plafond

  UserSavingsAccountView({
    required this.id,
    required this.balance,
    required this.interestAccrued,
    required this.savingsAccountName,
    required this.bankName,
    required this.cap,
  });
}