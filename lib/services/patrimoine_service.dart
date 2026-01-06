import '../models/local_database.dart';
import 'investment_service.dart';

class PatrimoineService {
  final LocalDatabase db;
  final InvestmentService investmentService;

  PatrimoineService(this.db) : investmentService = InvestmentService(db);

  /// Calcule le patrimoine total d'un utilisateur
  Future<double> getTotalPatrimoineForUser(int userId) async {
    // Total espèces
    final cashTotal = db.userCashAccounts
        .where((uca) => uca.userId == userId)
        .fold(0.0, (total, account) => total + account.balance);

    // Total épargne (balance + intérêts)
    final savingsTotal = db.userSavingsAccounts
        .where((usa) => usa.userId == userId)
        .fold(0.0, (total, account) => total + account.balance + account.interestAccrued);

    // Total investissements (utilise InvestmentService) ✅
    final investmentsTotal = await investmentService.getUserInvestmentsTotalValue(userId);

    // Total titres restaurant
    final vouchersTotal = db.userRestaurantVouchers
        .where((urv) => urv.userId == userId)
        .fold(0.0, (total, voucher) => total + voucher.balance);

    return cashTotal + savingsTotal + investmentsTotal + vouchersTotal;
  }

  double getTotalSavingsForUser(int userId) {
    return db.userSavingsAccounts
        .where((usa) => usa.userId == userId)
        .fold(0.0, (total, account) => total + account.balance + account.interestAccrued);
  }

  Future<double> getTotalInvestmentsForUser(int userId) async {
    return await investmentService.getUserInvestmentsTotalValue(userId);
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