import '../models/local_database.dart';
import '../models/investment_position.dart';

class InvestmentService {
  final LocalDatabase db;

  InvestmentService(this.db);

  // Récupère les positions pour un compte d'investissement spécifique
  List<InvestmentPosition> getPositionsForAccount(int userInvestmentAccountId) {
    return db.investmentPositions
        .where((pos) => pos.userInvestmentAccountId == userInvestmentAccountId)
        .toList();
  }

  // Récupère les comptes d'investissement pour un utilisateur
  List<UserInvestmentAccountView> getInvestmentAccountsForUser(int userId) {
    final accounts = db.userInvestmentAccounts
        .where((uia) => uia.userId == userId)
        .toList();

    return accounts.map((uia) {
      final account = db.investmentAccounts
          .firstWhere((a) => a.id == uia.investmentAccountId);
      final bank = db.banks.firstWhere((b) => b.id == account.bankId);

      // Compte le nombre de positions
      final positionCount = db.investmentPositions
          .where((pos) => pos.userInvestmentAccountId == uia.id)
          .length;

      return UserInvestmentAccountView(
        id: uia.id,
        balance: uia.balance,
        latentCapitalGain: uia.latentCapitalGain,
        investmentAccountName: account.name,
        bankName: bank.name,
        positionCount: positionCount,
      );
    }).toList();
  }

  // Calcule le total des investissements pour un utilisateur
  double getTotalInvestmentValue(int userId) {
    final accounts = db.userInvestmentAccounts
        .where((uia) => uia.userId == userId)
        .toList();

    return accounts.fold(0.0, (sum, account) => sum + account.balance);
  }

  // Calcule le total des plus-values latentes
  double getTotalLatentCapitalGain(int userId) {
    final accounts = db.userInvestmentAccounts
        .where((uia) => uia.userId == userId)
        .toList();

    return accounts.fold(0.0, (sum, account) => sum + account.latentCapitalGain);
  }
}

// Classe view pour l'affichage des comptes d'investissement
class UserInvestmentAccountView {
  final int id;
  final double balance;
  final double latentCapitalGain;
  final String investmentAccountName;
  final String bankName;
  final int positionCount;

  UserInvestmentAccountView({
    required this.id,
    required this.balance,
    required this.latentCapitalGain,
    required this.investmentAccountName,
    required this.bankName,
    required this.positionCount,
  });
}