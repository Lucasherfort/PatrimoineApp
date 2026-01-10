import 'package:flutter/foundation.dart';
import '../models/local_database.dart';
import '../models/investment_position.dart';
import '../models/user_investment_account.dart';
import '../repositories/local_database_repository.dart';
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
      if (kDebugMode)
      {
        debugPrint('Erreur lors de la récupération des données Google Sheets: $e',
        );
      }
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

  // ========== Méthode de mise à jour ==========
// À ajouter dans la classe InvestmentService

  /// Met à jour le PRU et la quantité d'une position d'investissement
  Future<bool> updatePosition({
    required InvestmentPosition position,
    required double averagePurchasePrice,
    required double quantity,
  }) async {
    // Trouver l'index de la position dans la base de données
    final index = db.investmentPositions.indexWhere((p) => p.id == position.id);

    if (index == -1) {
      throw Exception('Position non trouvée dans la base de données');
    }

    final oldPosition = db.investmentPositions[index];

    // ✅ Vérifie si les valeurs ont changé
    if (oldPosition.averagePurchasePrice == averagePurchasePrice &&
        oldPosition.quantity == quantity) {

      return false; // Pas de changement
    }

    // Créer une nouvelle instance avec les valeurs mises à jour
    final updatedPosition = InvestmentPosition(
      id: position.id,
      userInvestmentAccountId: position.userInvestmentAccountId,
      ticker: position.ticker,
      name: position.name,
      supportType: position.supportType,
      quantity: quantity, // ✅ Nouvelle quantité
      averagePurchasePrice: averagePurchasePrice, // ✅ Nouveau PRU
      currentPrice: position.currentPrice,
      currency: position.currency,
      priceOpen: position.priceOpen,
      high: position.high,
      low: position.low,
      volume: position.volume,
    );

    // Remplacer l'ancienne position par la nouvelle dans la base de données
    db.investmentPositions[index] = updatedPosition;

    // ✅ Sauvegarder dans le fichier JSON
    final repo = LocalDatabaseRepository();
    await repo.save(db);

    return true;
  }

  /// Variante si vous préférez passer l'ID de la position
  Future<bool> updatePositionById({
    required int positionId,
    required double averagePurchasePrice,
    required double quantity,
  }) async {
    final position = db.investmentPositions.firstWhere(
          (p) => p.id == positionId,
      orElse: () => throw Exception('Position non trouvée'),
    );

    return await updatePosition(
      position: position,
      averagePurchasePrice: averagePurchasePrice,
      quantity: quantity,
    );
  }

  // ========== Méthode d'ajout de position ==========
// À ajouter dans la classe InvestmentService

  /// Ajoute une nouvelle position d'investissement
  Future<InvestmentPosition> addPosition({
    required int userInvestmentAccountId,
    required String ticker,
    required String name,
    required double quantity,
    required double averagePurchasePrice,
    String supportType = 'ETF',
  }) async {
    // Trouver le prochain ID disponible
    final maxId = db.investmentPositions.isEmpty
        ? 0
        : db.investmentPositions.map((p) => p.id).reduce((a, b) => a > b ? a : b);

    final newId = maxId + 1;

    // Créer la nouvelle position
    final newPosition = InvestmentPosition(
      id: newId,
      userInvestmentAccountId: userInvestmentAccountId,
      ticker: ticker.toUpperCase(),
      name: name,
      supportType: supportType,
      quantity: quantity,
      averagePurchasePrice: averagePurchasePrice,
    );

    // Ajouter à la base de données
    db.investmentPositions.add(newPosition);

    // Tenter de récupérer le prix actuel depuis Google Sheets
    try {
      final etfsData = await sheetsService.fetchEtfs();
      final etfData = etfsData.firstWhere(
            (etf) => etf['ticker']?.toString().toUpperCase() == ticker.toUpperCase(),
        orElse: () => <String, dynamic>{},
      );

      if (etfData.isNotEmpty) {
        newPosition.updateFromSheet(etfData);
      }
    }catch (e, stackTrace)
    {
      if (kDebugMode)
      {
        debugPrint('Impossible de récupérer le prix actuel:\n$e\n$stackTrace');
      }
    }

    // Sauvegarder dans le fichier JSON
    final repo = LocalDatabaseRepository();
    await repo.save(db);

    return newPosition;
  }

  // ========== Méthode de suppression de position ==========

  /// Supprime une position d'investissement
  Future<bool> deletePosition(InvestmentPosition position) async {
    // Trouver l'index de la position
    final index = db.investmentPositions.indexWhere((p) => p.id == position.id);

    if (index == -1) {
      throw Exception('Position non trouvée');
    }

    // Supprimer de la liste
    db.investmentPositions.removeAt(index);

    // Sauvegarder dans le fichier JSON
    final repo = LocalDatabaseRepository();
    await repo.save(db);

    return true;
  }

  // ========== Méthode de mise à jour du compte ==========

  /// Met à jour les espèces et les versements cumulés d'un compte d'investissement
  Future<bool> updateInvestmentAccount({
    required int userInvestmentAccountId,
    required double cashBalance,
    required double cumulativeDeposits,
  }) async {
    // Trouver le compte utilisateur
    final account = db.userInvestmentAccounts.firstWhere(
          (uia) => uia.id == userInvestmentAccountId,
      orElse: () => throw Exception('Compte d\'investissement non trouvé'),
    );

    // ✅ Vérifie si les valeurs ont changé
    if (account.cashBalance == cashBalance &&
        account.cumulativeDeposits == cumulativeDeposits) {
      return false;
    }

    // Mettre à jour directement les propriétés
    account.cashBalance = cashBalance;
    account.cumulativeDeposits = cumulativeDeposits;

    // Sauvegarder dans le fichier JSON
    final repo = LocalDatabaseRepository();
    await repo.save(db);

    return true;
  }

  /// Supprime un compte utilisateur et toutes ses positions
  Future<bool> deleteUserInvestmentAccount(int userInvestmentAccountId) async {
    // Supprimer les positions
    db.investmentPositions
        .removeWhere((pos) => pos.userInvestmentAccountId == userInvestmentAccountId);

    // Supprimer le compte
    db.userInvestmentAccounts
        .removeWhere((uac) => uac.id == userInvestmentAccountId);

    // Sauvegarder la DB
    final repo = LocalDatabaseRepository();
    await repo.save(db);

    return true;
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