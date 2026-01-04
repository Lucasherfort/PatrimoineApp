import '../models/local_database.dart';
import '../models/user_cash_account.dart';
import '../models/cash_account.dart';
import '../models/bank.dart';

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
}

class UserCashAccountView {
  final double balance;
  final String cashAccountName;
  final String bankName;

  UserCashAccountView({
    required this.balance,
    required this.cashAccountName,
    required this.bankName,
  });
}