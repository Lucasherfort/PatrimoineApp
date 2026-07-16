import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bdd/banks_table.dart';
import '../bdd/investment_category_table.dart';
import '../bdd/investment_source_table.dart';
import '../bdd/positions_table.dart';
import '../bdd/storage_buckets.dart';
import '../bdd/user_investment_account_table.dart';
import '../bdd/user_investment_position_table.dart';
import '../bdd/application_fiscality_table.dart';
import '../models/investment_position.dart';
import '../models/investments/application_fiscality.dart';
import '../models/investments/user_investment_account_view.dart';
import '../models/investments/estimated_gains_result.dart';
import '../models/user_investment_account.dart';
import 'theme_manager.dart';

class InvestmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static final InvestmentService _instance = InvestmentService._internal();
  factory InvestmentService() => _instance;
  InvestmentService._internal();

  // ─── Requêtes SELECT ────────────────────────────────────────────────────────

  static const _selectAccountsWithPrices =
      '''
    ${UserInvestmentAccountTable.id},
    ${UserInvestmentAccountTable.totalContribution},
    ${UserInvestmentAccountTable.cashBalance},
    ${UserInvestmentAccountTable.amount},
    ${UserInvestmentAccountTable.openedAt},
    ${InvestmentSourceTable.tableName} (
      ${InvestmentSourceTable.id},
      ${InvestmentSourceTable.bankId},
      ${InvestmentSourceTable.investmentCategoryId},
      ${BanksTable.tableName} (
        ${BanksTable.id},
        ${BanksTable.name},
        ${BanksTable.icon}
      ),
      ${InvestmentCategoryTable.tableName} (
        ${InvestmentCategoryTable.name}
      )
    )
  ''';

  static const _selectSourceWithBank =
      '''
    *,
    ${BanksTable.tableName} (
      ${BanksTable.name},
      ${BanksTable.icon}
    )
  ''';

  static const _selectPositions =
      '''
    ${UserInvestmentPositionTable.id},
    ${UserInvestmentPositionTable.userInvestmentAccountId},
    ${UserInvestmentPositionTable.quantity},
    ${UserInvestmentPositionTable.pru},
    ${PositionsTable.tableName}!inner(
      ${PositionsTable.id},
      ${PositionsTable.ticker},
      ${PositionsTable.name},
      ${PositionsTable.type},
      ${PositionsTable.price}
    )
  ''';

  // ─── Fiscalité ──────────────────────────────────────────────────────────────

  List<ApplicationFiscality> _fiscalRules = [];

  Future<void> _loadFiscalRules() async {
    if (_fiscalRules.isNotEmpty) return;
    try {
      final response = await _supabase
          .from(ApplicationFiscalityTable.tableName)
          .select();
      _fiscalRules = response
          .map<ApplicationFiscality>((e) => ApplicationFiscality.fromMap(e))
          .toList();
    } catch (e) {
      debugPrint("Erreur chargement fiscalité: $e");
    }
  }

  /// Applique les règles de fiscalité selon le ticket #29
  double calculateNetValue(UserInvestmentAccountView account) {
    if (!ThemeManager().displayNetWealth) return account.amount;

    final gains = account.amount - account.totalContribution;
    if (gains <= 0) return account.amount;

    final taxRate = getCurrentTaxRate(account);
    return account.amount - (gains * taxRate);
  }

  double getCurrentTaxRate(UserInvestmentAccountView account) {
    if (account.openedAt == null) return 0.30;

    final ageInYears =
        DateTime.now().difference(account.openedAt!).inDays / 365.25;

    final rule = _fiscalRules.where((r) {
      if (r.investmentCategoryId != account.investmentCategoryId) return false;
      if (ageInYears < r.minHoldingYears) return false;
      if (r.maxHoldingYears != null && ageInYears > r.maxHoldingYears!) {
        return false;
      }
      return true;
    }).firstOrNull;

    if (rule == null) return 0.30; // Défaut Flat Tax (30%)
    return rule.incomeTaxRate + rule.socialContributionRate;
  }

  bool isTaxAdvantageAcquired(UserInvestmentAccountView account) {
    if (account.openedAt == null) return false;

    final ageInYears =
        DateTime.now().difference(account.openedAt!).inDays / 365.25;

    final rules = _fiscalRules
        .where((r) => r.investmentCategoryId == account.investmentCategoryId)
        .toList();
    if (rules.isEmpty) return false;

    // Trier par ancienneté requise décroissante pour trouver le "meilleur" avantage
    rules.sort((a, b) => b.minHoldingYears.compareTo(a.minHoldingYears));
    final bestRule = rules.first;

    return ageInYears >= bestRule.minHoldingYears;
  }

  // ─── Lecture ────────────────────────────────────────────────────────────────

  Future<List<UserInvestmentAccountView>>
  getInvestmentAccountsForUserWithPrices() async {
    try {
      await _loadFiscalRules();
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final response = await _supabase
          .from(UserInvestmentAccountTable.tableName)
          .select(_selectAccountsWithPrices)
          .eq(UserInvestmentAccountTable.userId, user.id);

      final List<UserInvestmentAccountView> accounts = [];

      for (var item in response) {
        final view = _mapToAccountView(item);

        // La colonne 'amount' en base est souvent vide ou pas à jour.
        // On recalcule la valorisation réelle (Positions + Espèces).
        final positionsValue = await getPositionsValueForAccount(view.id);
        view.amount = view.cashBalance + positionsValue;

        accounts.add(view);
      }

      return accounts;
    } catch (e) {
      debugPrint('Erreur getInvestmentAccountsForUserWithPrices: $e');
      return [];
    }
  }

  Future<List<UserInvestmentAccount>> getUserInvestmentAccounts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final response = await _supabase
        .from(UserInvestmentAccountTable.tableName)
        .select()
        .eq(UserInvestmentAccountTable.userId, user.id);

    return response
        .map<UserInvestmentAccount>((e) => UserInvestmentAccount.fromMap(e))
        .toList();
  }

  Future<List<UserInvestmentAccountView>>
  getUserInvestmentAccountsView() async {
    await _loadFiscalRules();
    final uiaList = await getUserInvestmentAccounts();
    final List<UserInvestmentAccountView> views = [];

    for (final uia in uiaList) {
      final source = await _supabase
          .from(InvestmentSourceTable.tableName)
          .select(_selectSourceWithBank)
          .eq(InvestmentSourceTable.id, uia.investmentSourceId!)
          .single();

      final categoryId =
          (source[InvestmentSourceTable.investmentCategoryId] as num).toInt();
      final category = await _supabase
          .from(InvestmentCategoryTable.tableName)
          .select(InvestmentCategoryTable.name)
          .eq(InvestmentCategoryTable.id, categoryId)
          .single();

      final bank = source[BanksTable.tableName] as Map<String, dynamic>;
      final totalAmount = await getTotalValueOfInvestmentAccount(uia);

      views.add(
        UserInvestmentAccountView(
          id: uia.id,
          investmentCategoryId: categoryId,
          sourceName: category[InvestmentCategoryTable.name] as String,
          bankName: bank[BanksTable.name] as String,
          logoUrl: _resolveLogoUrl(bank[BanksTable.icon] as String?),
          totalContribution: uia.cumulativeDeposits,
          cashBalance: uia.cashBalance,
          amount: totalAmount,
          openedAt: uia.openedAt,
        ),
      );
    }

    return views;
  }

  Future<List<InvestmentPosition>> getInvestmentPositions(
    int userInvestmentAccountId,
  ) async {
    try {
      final response = await _supabase
          .from(UserInvestmentPositionTable.tableName)
          .select(_selectPositions)
          .eq(
            UserInvestmentPositionTable.userInvestmentAccountId,
            userInvestmentAccountId,
          )
          .order(UserInvestmentPositionTable.createdAt);

      final positions = response.map<InvestmentPosition>((e) {
        final position = InvestmentPosition.fromMap(e);

        return position;
      }).toList();

      return positions;
    } catch (e) {
      rethrow;
    }
  }

  // ─── Calculs ─────────────────────────────────────────────────────────────────

  /// Calcule le rendement annualisé estimé d'un compte d'investissement.
  /// Formule : (Valorisation actuelle / Montant total versé) ^ (1 / nombre d'années) - 1
  double? calculateAnnualizedReturn({
    required double totalContribution,
    required double currentValuation,
    required DateTime? openedAt,
  }) {
    if (openedAt == null || totalContribution <= 0) return null;

    final now = DateTime.now();
    final difference = now.difference(openedAt);

    // Si le compte a moins de 1 jour, on ne calcule pas de rendement annualisé significatif
    if (difference.inDays < 1) return null;

    final years = difference.inDays / 365.25;

    if (currentValuation <= 0) return -1.0; // Perte totale

    try {
      return pow(currentValuation / totalContribution, 1 / years) - 1;
    } catch (e) {
      return null;
    }
  }

  /// Calcule la valeur totale des investissements d'un utilisateur ✅
  Future<double> getTotalPortfolioValue() async {
    final accounts = await getUserInvestmentAccountsView();
    double total = 0.0;
    for (final account in accounts) {
      total += calculateNetValue(account);
    }
    return total;
  }

  /// Calcule le montant total des gains annuels estimés du patrimoine.
  /// Somme(valorisation actuelle * rendement annualisé)
  Future<EstimatedGainsResult> getDetailedEstimatedAnnualGains() async {
    final accounts = await getInvestmentAccountsForUserWithPrices();
    double totalGains = 0.0;
    int calculableAccounts = 0;
    bool hasRecentAccounts = false;
    bool hasMissingDates = false;

    for (final account in accounts) {
      if (account.openedAt == null) {
        hasMissingDates = true;
      } else {
        final now = DateTime.now();
        if (now.difference(account.openedAt!).inDays < 1) {
          hasRecentAccounts = true;
        }
      }

      final annualizedReturn = calculateAnnualizedReturn(
        totalContribution: account.totalContribution,
        currentValuation: account.amount,
        openedAt: account.openedAt,
      );

      if (annualizedReturn != null) {
        totalGains += account.amount * annualizedReturn;
        calculableAccounts++;
      }
    }

    return EstimatedGainsResult(
      totalGains: totalGains,
      totalAccounts: accounts.length,
      calculableAccounts: calculableAccounts,
      hasRecentAccounts: hasRecentAccounts,
      hasMissingDates: hasMissingDates,
    );
  }

  Future<double> getTotalEstimatedAnnualGains() async {
    final result = await getDetailedEstimatedAnnualGains();
    return result.totalGains;
  }

  /// Alias pour getTotalPortfolioValue
  Future<double> getUserInvestmentsTotalValue() => getTotalPortfolioValue();

  Future<double> getTotalValueOfInvestmentAccount(
    UserInvestmentAccount account,
  ) async {
    final positionsValue = await getPositionsValueForAccount(account.id);
    return account.cashBalance + positionsValue;
  }

  Future<double> getPositionsValueForAccount(
    int userInvestmentAccountId,
  ) async {
    final positions = await getInvestmentPositions(userInvestmentAccountId);
    return positions.fold<double>(0.0, (sum, p) => sum + p.totalValue);
  }

  // ─── Écriture ────────────────────────────────────────────────────────────────

  Future<bool> updateInvestmentAccount({
    required int userInvestmentAccountId,
    required double cashBalance,
    required double cumulativeDeposits,
    DateTime? openedAt,
  }) async {
    final current = await _supabase
        .from(UserInvestmentAccountTable.tableName)
        .select(
          '${UserInvestmentAccountTable.cashBalance}, ${UserInvestmentAccountTable.totalContribution}, ${UserInvestmentAccountTable.openedAt}',
        )
        .eq(UserInvestmentAccountTable.id, userInvestmentAccountId)
        .single();

    final currentCash =
        (current[UserInvestmentAccountTable.cashBalance] as num?)?.toDouble() ??
        0.0;
    final currentDeposits =
        (current[UserInvestmentAccountTable.totalContribution] as num?)
            ?.toDouble() ??
        0.0;
    final currentOpenedAtStr =
        current[UserInvestmentAccountTable.openedAt] as String?;
    final currentOpenedAt = currentOpenedAtStr != null
        ? DateTime.tryParse(currentOpenedAtStr)
        : null;

    if (currentCash == cashBalance &&
        currentDeposits == cumulativeDeposits &&
        currentOpenedAt == openedAt) {
      return false;
    }

    await _supabase
        .from(UserInvestmentAccountTable.tableName)
        .update({
          UserInvestmentAccountTable.cashBalance: cashBalance,
          UserInvestmentAccountTable.totalContribution: cumulativeDeposits,
          UserInvestmentAccountTable.openedAt: openedAt?.toIso8601String(),
          UserInvestmentAccountTable.updatedAt: DateTime.now()
              .toIso8601String(),
        })
        .eq(UserInvestmentAccountTable.id, userInvestmentAccountId);

    return true;
  }

  Future<void> deleteUserInvestmentAccount(int accountId) async {
    await _supabase
        .from(UserInvestmentAccountTable.tableName)
        .delete()
        .eq(UserInvestmentAccountTable.id, accountId);
  }

  // ─── Helpers privés ──────────────────────────────────────────────────────────

  UserInvestmentAccountView _mapToAccountView(Map<String, dynamic> item) {
    final source =
        item[InvestmentSourceTable.tableName] as Map<String, dynamic>? ?? {};
    final bank = source[BanksTable.tableName] as Map<String, dynamic>? ?? {};
    final category =
        source[InvestmentCategoryTable.tableName] as Map<String, dynamic>? ??
        {};

    return UserInvestmentAccountView(
      id: item[UserInvestmentAccountTable.id] as int,
      investmentCategoryId:
          (source[InvestmentSourceTable.investmentCategoryId] as num?)
              ?.toInt() ??
          0,
      sourceName:
          (category[InvestmentCategoryTable.name] as String?) ?? 'Compte',
      bankName: (bank[BanksTable.name] as String?) ?? 'Banque',
      logoUrl: _resolveLogoUrl(bank[BanksTable.icon] as String?),
      totalContribution:
          (item[UserInvestmentAccountTable.totalContribution] as num?)
              ?.toDouble() ??
          0.0,
      cashBalance:
          (item[UserInvestmentAccountTable.cashBalance] as num?)?.toDouble() ??
          0.0,
      amount:
          (item[UserInvestmentAccountTable.amount] as num?)?.toDouble() ?? 0.0,
      openedAt: item[UserInvestmentAccountTable.openedAt] != null
          ? DateTime.tryParse(
              item[UserInvestmentAccountTable.openedAt] as String,
            )
          : null,
    );
  }

  String _resolveLogoUrl(String? iconPath) {
    if (iconPath == null || iconPath.isEmpty) return '';
    return _supabase.storage
        .from(StorageBucketsTable.banksIcons)
        .getPublicUrl(iconPath);
  }
}
