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
        cap: account.cap, // ✅ Ajout du plafond
      );
    }).toList();
  }

  double getTotalSavingsForUser(int userId) {
    return db.userSavingsAccounts
        .where((usa) => usa.userId == userId)
        .fold(0.0, (total, account) => total + account.balance + account.interestAccrued);
  }

  // ✅ Méthode pour mettre à jour un compte épargne avec validation du plafond
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

    // Vérifie si au moins une valeur a changé
    if (oldAccount.balance == newBalance && oldAccount.interestAccrued == newInterest) {
      print('ℹ️ Compte épargne $accountId: aucun changement');
      return SavingsAccountUpdateResult(success: false);
    }

    // ✅ Récupère le plafond du compte
    final savingsAccount = db.savingsAccounts
        .firstWhere((sa) => sa.id == oldAccount.savingsAccountId);

    // ✅ Vérifie que le solde ne dépasse pas le plafond
    if (newBalance > savingsAccount.cap) {
      print('⚠️ Compte épargne $accountId: plafond dépassé (${newBalance} € > ${savingsAccount.cap} €)');
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

    print('✅ Compte épargne $accountId mis à jour:');
    print('   Balance: ${oldAccount.balance} € → $newBalance €');
    print('   Intérêts: ${oldAccount.interestAccrued} € → $newInterest €');

    return SavingsAccountUpdateResult(success: true);
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