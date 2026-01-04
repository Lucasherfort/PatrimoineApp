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
      // Récupère tous les ETFs depuis Google Sheets
      final etfsData = await sheetsService.fetchEtfs();

      // Crée une map pour un accès rapide par ticker
      final etfsMap = <String, Map<String, dynamic>>{};
      for (final etf in etfsData) {
        final ticker = etf['ticker']?.toString().toUpperCase();
        if (ticker != null) {
          etfsMap[ticker] = etf;
        }
      }

      // Met à jour chaque position avec les données du sheet
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

  // Récupère les comptes d'investissement pour un utilisateur
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

      return UserInvestmentAccountView(
        id: uia.id,
        balance: uia.balance,
        latentCapitalGain: uia.latentCapitalGain,
        cashBalance: uia.cashBalance, // ✅ Ajout
        investmentAccountName: account.name,
        bankName: bank.name,
        positionCount: positionCount,
      );
    }).toList();
  }

  double getTotalInvestmentValue(int userId) {
    final accounts = db.userInvestmentAccounts
        .where((uia) => uia.userId == userId)
        .toList();

    return accounts.fold(0.0, (sum, account) => sum + account.balance);
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
  final double balance;
  final double latentCapitalGain;
  final double cashBalance; // ✅ Nouveau champ
  final String investmentAccountName;
  final String bankName;
  final int positionCount;

  UserInvestmentAccountView({
    required this.id,
    required this.balance,
    required this.latentCapitalGain,
    required this.cashBalance,
    required this.investmentAccountName,
    required this.bankName,
    required this.positionCount,
  });
}