import '../models/local_database.dart';
import '../models/investment_position.dart';
import 'google_sheet_service.dart';

class InvestmentService {
  final LocalDatabase db;
  final GoogleSheetsService sheetsService;

  InvestmentService(this.db)
      : sheetsService = GoogleSheetsService();

  // Récupère les positions pour un compte d'investissement spécifique
  List<InvestmentPosition> getPositionsForAccount(int userInvestmentAccountId) {
    return db.investmentPositions
        .where((pos) => pos.userInvestmentAccountId == userInvestmentAccountId)
        .toList();
  }

  // Récupère les positions avec les prix depuis Google Sheets
  Future<List<InvestmentPosition>> getPositionsWithPrices(int userInvestmentAccountId) async {
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

  // ✅ Nouvelle méthode pour obtenir les comptes avec les vrais prix
  Future<List<UserInvestmentAccountView>> getInvestmentAccountsForUserWithPrices(int userId) async {
    final accounts = db.userInvestmentAccounts
        .where((uia) => uia.userId == userId)
        .toList();

    final List<UserInvestmentAccountView> result = [];

    for (final uia in accounts) {
      final account = db.investmentAccounts
          .firstWhere((a) => a.id == uia.investmentAccountId);
      final bank = db.banks.firstWhere((b) => b.id == account.bankId);

      print('🔍 [InvestmentList] Compte: ${account.name}');
      print('💰 [InvestmentList] Cash Balance: ${uia.cashBalance}');

      // Récupère les positions avec les prix depuis Google Sheets
      final positions = await getPositionsWithPrices(uia.id);

      print('📊 [InvestmentList] Nombre de positions: ${positions.length}');

      final positionCount = positions.length;

      // Calcule la valeur totale des positions avec les vrais prix
      final positionsValue = positions.fold(0.0, (sum, pos) {
        print('   - ${pos.ticker}: qty=${pos.quantity}, price=${pos.currentPrice ?? pos.averagePurchasePrice}, total=${pos.totalValue}');
        return sum + pos.totalValue;
      });

      print('📈 [InvestmentList] Valeur des positions: $positionsValue');

      // Valeur totale = espèces + valeur des positions
      final totalValue = uia.cashBalance + positionsValue;

      print('💵 [InvestmentList] Valeur totale: $totalValue');

      // Rendement = (valeur totale - versements) / versements * 100
      final performance = uia.cumulativeDeposits > 0
          ? ((totalValue - uia.cumulativeDeposits) / uia.cumulativeDeposits) * 100
          : 0.0;

      print('📊 [InvestmentList] Versements: ${uia.cumulativeDeposits}');
      print('🎯 [InvestmentList] Performance: $performance%');
      print('---');

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

  // Ancienne méthode sans les prix (garde pour compatibilité)
  List<UserInvestmentAccountView> getInvestmentAccountsForUser(int userId) {
    final accounts = db.userInvestmentAccounts
        .where((uia) => uia.userId == userId)
        .toList();

    return accounts.map((uia) {
      final account = db.investmentAccounts
          .firstWhere((a) => a.id == uia.investmentAccountId);
      final bank = db.banks.firstWhere((b) => b.id == account.bankId);

      final positionCount = db.investmentPositions
          .where((pos) => pos.userInvestmentAccountId == uia.id)
          .length;

      // Calcul basique sans les prix à jour
      final positionsValue = db.investmentPositions
          .where((pos) => pos.userInvestmentAccountId == uia.id)
          .fold(0.0, (sum, pos) {
        final currentPrice = pos.currentPrice ?? pos.averagePurchasePrice;
        return sum + (currentPrice * pos.quantity);
      });

      final totalValue = uia.cashBalance + positionsValue;

      final performance = uia.cumulativeDeposits > 0
          ? ((totalValue - uia.cumulativeDeposits) / uia.cumulativeDeposits) * 100
          : 0.0;

      return UserInvestmentAccountView(
        id: uia.id,
        cumulativeDeposits: uia.cumulativeDeposits,
        latentCapitalGain: uia.latentCapitalGain,
        cashBalance: uia.cashBalance,
        investmentAccountName: account.name,
        bankName: bank.name,
        positionCount: positionCount,
        totalValue: totalValue,
        performance: performance,
      );
    }).toList();
  }

  double getTotalInvestmentValue(int userId) {
    final accounts = db.userInvestmentAccounts
        .where((uia) => uia.userId == userId)
        .toList();

    return accounts.fold(0.0, (sum, account) => sum + account.cumulativeDeposits);
  }

  double getTotalLatentCapitalGain(int userId) {
    final accounts = db.userInvestmentAccounts
        .where((uia) => uia.userId == userId)
        .toList();

    return accounts.fold(0.0, (sum, account) => sum + account.latentCapitalGain);
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
