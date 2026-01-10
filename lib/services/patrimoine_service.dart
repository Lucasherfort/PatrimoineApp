import '../models/bank.dart';
import '../models/local_database.dart';
import '../models/patrimoine_type.dart';
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
      // 1. Récupérer le SavingsAccount
      final savingsAccount = db.savingsAccounts
          .firstWhere((sa) => sa.id == usa.savingsAccountId);

      // 2. Récupérer le SavingsAccountType pour avoir le nom
      final savingsAccountType = db.savingsAccountTypes
          .firstWhere((sat) => sat.id == savingsAccount.savingsAccountTypeId);

      // 3. Récupérer la Bank
      final bank = db.banks
          .firstWhere((b) => b.id == savingsAccount.bankId);

      return UserSavingsAccountView(
        id: usa.id,
        balance: usa.balance,
        interestAccrued: usa.interestAccrued,
        savingsAccountName: savingsAccountType.name, // ✅ Nom du type
        bankName: bank.name,
        interestRate: savingsAccountType.interestRate,
        cap: savingsAccountType.cap,
      );
    }).toList();
  }

  List<Bank> getAvailableBanksForType(PatrimoineType type) {
    switch (type.entityType) {
      case 'cashAccount':
        return db.banks;
      case 'savingsAccount':
        final savingsType = db.savingsAccountTypes.firstWhere(
              (sat) => sat.name == type.name,
          orElse: () => throw Exception('Type épargne "${type.name}" introuvable'),
        );
        final bankIds = db.savingsAccounts
            .where((sa) => sa.savingsAccountTypeId == savingsType.id)
            .map((sa) => sa.bankId)
            .toSet();
        return db.banks.where((b) => bankIds.contains(b.id)).toList();
      case 'investmentAccount':
        final bankIds = db.investmentAccounts
            .where((ia) => ia.name == type.name)
            .map((ia) => ia.bankId)
            .toSet();
        return db.banks.where((b) => bankIds.contains(b.id)).toList();
      default:
        return db.banks;
    }
  }
}

class UserSavingsAccountView {
  final int id;
  final double balance;
  final double interestAccrued;
  final String savingsAccountName;
  final String bankName;
  final double interestRate;
  final double cap;

  UserSavingsAccountView({
    required this.id,
    required this.balance,
    required this.interestAccrued,
    required this.savingsAccountName,
    required this.bankName,
    required this.interestRate,
    required this.cap,
  });
}