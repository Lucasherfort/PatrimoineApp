import '../models/local_database.dart';
import '../models/investment_position.dart';
import '../models/user_investment_account.dart';
import 'google_sheet_service.dart';

class InvestmentService {
  final LocalDatabase db;
  final GoogleSheetsService sheetsService;

  InvestmentService(this.db)
      : sheetsService = GoogleSheetsService();

  // ========== Méthodes de base ==========

  List<InvestmentPosition> getPositionsForAccount(int userInvestmentAccountId) {
    return db.investmentPositions
        .where((pos) => pos.userInvestmentAccountId == userInvestmentAccountId)
        .toList();
  }

  /*
  Récupère la liste des positions d'un compte d'investissement depuis le googel sheet
   */
  Future<List<InvestmentPosition>> getInvestmentPositions(int userInvestmentAccountId) async {
    final positions = getPositionsForAccount(userInvestmentAccountId);

    if (positions.isEmpty) {
      return positions;
    }

    try {
      final etfsData = await sheetsService.fetchEtfs();

      final etfsMap = <String, Map<String, dynamic>>{};
      for (final etf in etfsData) {
        final ticker = etf['ticker']?.toString().toUpperCase();
        if (ticker != null) {
          etfsMap[ticker] = etf;
        }
      }

      for (final position in positions) {
        final etfData = etfsMap[position.ticker.toUpperCase()];
        if (etfData != null) {
          position.updateFromSheet(etfData);
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des données Google Sheets: $e');
    }

    return positions;
  }

  // ========== Méthodes de calcul ==========

  /// Récupère la valeur totale des positions d'un compte
  Future<double> getPositionsValueForAccount(UserInvestmentAccount uia) async {
    final positions = await getInvestmentPositions(uia.id);

    double result = 0;
    for(int c = 0 ; c < positions.length ; c++)
      {
        result += positions[c].totalValue;
      }

    return result;
  }

  /// Récupère la valeur totale d'un compte d'investissement (espèces + titres)
  Future<double> getTotalValueOfInvestmentAccount(UserInvestmentAccount account) async {
    final positionsValue = await getPositionsValueForAccount(account);
    return account.cashBalance + positionsValue;
  }

  /// Récupère la valeur totale de tous les comptes d'investissement d'un utilisateur
  Future<double> getUserInvestmentsTotalValue(int userId) async {
    final accounts = db.userInvestmentAccounts
        .where((uia) => uia.userId == userId)
        .toList();

    double total = 0.0;

    for (final account in accounts) {
      total += await getTotalValueOfInvestmentAccount(account);
    }

    return total;
  }

  /// Calcule la plus-value totale d'un utilisateur
  Future<double> getUserTotalProfitLoss(int userId) async {
    final accounts = db.userInvestmentAccounts
        .where((uia) => uia.userId == userId)
        .toList();

    double totalValue = 0.0;
    double totalDeposits = 0.0;

    for (final account in accounts) {
      totalValue += await getTotalValueOfInvestmentAccount(account);
      totalDeposits += account.cumulativeDeposits;
    }

    return totalValue - totalDeposits;
  }

  /// Calcule le rendement total d'un utilisateur en %
  Future<double> getUserTotalPerformance(int userId) async {
    final accounts = db.userInvestmentAccounts
        .where((uia) => uia.userId == userId)
        .toList();

    double totalValue = 0.0;
    double totalDeposits = 0.0;

    for (final account in accounts) {
      totalValue += await getTotalValueOfInvestmentAccount(account);
      totalDeposits += account.cumulativeDeposits;
    }

    if (totalDeposits <= 0) return 0.0;
    return ((totalValue - totalDeposits) / totalDeposits) * 100;
  }

  // ========== Méthodes pour les vues ==========

  Future<List<UserInvestmentAccountView>> getInvestmentAccountsForUserWithPrices(int userId) async {
    final accounts = db.userInvestmentAccounts
        .where((uia) => uia.userId == userId)
        .toList();

    final List<UserInvestmentAccountView> result = [];

    for (final uia in accounts) {
      final account = db.investmentAccounts
          .firstWhere((a) => a.id == uia.investmentAccountId);
      final bank = db.banks.firstWhere((b) => b.id == account.bankId);

      final positions = await getInvestmentPositions(uia.id);
      final positionCount = positions.length;
      final positionsValue = positions.fold(0.0, (sum, pos) => sum + pos.totalValue);
      final totalValue = uia.cashBalance + positionsValue;
      final performance = uia.cumulativeDeposits > 0
          ? ((totalValue - uia.cumulativeDeposits) / uia.cumulativeDeposits) * 100
          : 0.0;

      result.add(UserInvestmentAccountView(
        id: uia.id,
        cumulativeDeposits: uia.cumulativeDeposits,
        latentCapitalGain: uia.latentCapitalGain,
        cashBalance: uia.cashBalance,
        investmentAccountName: account.name,
        bankName: bank.name,
        positionCount: positionCount,
        totalValue: totalValue,
        performance: performance,
      ));
    }

    return result;
  }
}

class UserInvestmentAccountView {
  final int id;
  final double cumulativeDeposits;
  final double latentCapitalGain;
  final double cashBalance;
  final String investmentAccountName;
  final String bankName;
  final int positionCount;
  final double totalValue;
  final double performance;

  UserInvestmentAccountView({
    required this.id,
    required this.cumulativeDeposits,
    required this.latentCapitalGain,
    required this.cashBalance,
    required this.investmentAccountName,
    required this.bankName,
    required this.positionCount,
    required this.totalValue,
    required this.performance,
  });
}