import '../models/local_database.dart';
import '../models/user_savings_account.dart';
import '../models/savings_account.dart';
import '../models/bank.dart';

class PatrimoineService {
  final LocalDatabase db;

  PatrimoineService(this.db);

  // Tous les comptes d'un user
  List<UserSavingsAccount> getAccountsForUser(int userId) {
    return db.userSavingsAccounts
        .where((usa) => usa.userId == userId)
        .toList();
  }

  // Compte épargne
  SavingsAccount getSavingsAccountById(int id) {
    return db.savingsAccounts.firstWhere((sa) => sa.id == id);
  }

  // Banque du compte
  Bank getBankForSavingsAccount(SavingsAccount sa) {
    return db.banks.firstWhere((b) => b.id == sa.bankId);
  }

  // ✅ Valeur totale d'un user (balance + intérêts)
  double getTotalPatrimoineForUser(int userId) {
    final accounts = getAccountsForUser(userId);
    double total = 0;
    for (var a in accounts) {
      total += a.balance + a.interestAccrued;
    }
    return total;
  }
}