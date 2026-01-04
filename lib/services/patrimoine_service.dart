import '../models/local_database.dart';

class PatrimoineService {
  final LocalDatabase db;

  PatrimoineService(this.db);

  double getTotalPatrimoineForUser(int userId) {
    // Total épargne (balance + intérêts)
    final savingsTotal = db.userSavingsAccounts
        .where((usa) => usa.userId == userId)
        .fold(0.0, (total, account) => total + account.balance + account.interestAccrued);


    // Total investissements (balance)
    final investmentsTotal = db.userInvestmentAccounts
        .where((uia) => uia.userId == userId)
        .fold(0.0, (total, account) => total + account.balance);

    // Total titres restaurant ✅ AJOUT
    final vouchersTotal = db.userRestaurantVouchers
        .where((urv) => urv.userId == userId)
        .fold(0.0, (total, voucher) => total + voucher.balance);

    return savingsTotal + investmentsTotal + vouchersTotal;
  }

  List<UserSavingsAccountView> getAccountsForUser(int userId) {
    final accounts = db.userSavingsAccounts
        .where((usa) => usa.userId == userId)
        .toList();

    return accounts.map((usa) {
      final account = db.savingsAccounts
          .firstWhere((a) => a.id == usa.savingsAccountId);
      final bank = db.banks.firstWhere((b) => b.id == account.bankId);
      return UserSavingsAccountView(
        balance: usa.balance,
        interestAccrued: usa.interestAccrued,
        savingsAccountName: account.name,
        bankName: bank.name,
      );
    }).toList();
  }
}

// Classe view pour l'affichage
class UserSavingsAccountView {
  final double balance;
  final double interestAccrued;
  final String savingsAccountName;
  final String bankName;

  UserSavingsAccountView({
    required this.balance,
    required this.interestAccrued,
    required this.savingsAccountName,
    required this.bankName,
  });
}