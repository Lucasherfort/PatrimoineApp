import 'package:patrimoine360/services/savings_account_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/patrimoine_category_table.dart';
import '../bdd/user_advantage_account_table.dart';
import '../bdd/user_investment_account_table.dart';
import '../bdd/user_liquidity_account_table.dart';
import '../bdd/user_savings_account_table.dart';
import '../models/patrimoine/patrimoine_category.dart';
import 'advantage_service.dart';
import 'investment_service.dart';
import 'liquidity_account_service.dart';

class PatrimoineService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static final PatrimoineService _instance = PatrimoineService._internal();
  factory PatrimoineService() => _instance;
  PatrimoineService._internal();

  final InvestmentService _investmentService = InvestmentService();

  // ─── Utils ────────────────────────────────────────────────────────────────

  String _requireUserId() {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');
    return user.id;
  }

  // ─── Total patrimoine ─────────────────────────────────────────────────────

  Future<double> getPatrimoine() async {
    final userId = _requireUserId();

    final liquidity = await _supabase
        .from(UserLiquidityAccountTable.tableName)
        .select(UserLiquidityAccountTable.amount)
        .eq(UserLiquidityAccountTable.userId, userId);

    final savings = await _supabase
        .from(UserSavingsAccountTable.tableName)
        .select(
          '${UserSavingsAccountTable.principal}, ${UserSavingsAccountTable.interest}',
        )
        .eq(UserSavingsAccountTable.userId, userId);

    final advantage = await _supabase
        .from(UserAdvantageAccountTable.tableName)
        .select(UserAdvantageAccountTable.value)
        .eq(UserAdvantageAccountTable.userId, userId);

    double total = 0.0;

    total += liquidity.fold<double>(
      0.0,
      (sum, row) =>
          sum +
          ((row[UserLiquidityAccountTable.amount] as num?)?.toDouble() ?? 0),
    );

    total += savings.fold<double>(
      0.0,
      (sum, row) =>
          sum +
          ((row[UserSavingsAccountTable.principal] as num?)?.toDouble() ?? 0) +
          ((row[UserSavingsAccountTable.interest] as num?)?.toDouble() ?? 0),
    );

    total += await _investmentService.getUserInvestmentsTotalValue();

    total += advantage.fold<double>(
      0.0,
      (sum, row) =>
          sum +
          ((row[UserAdvantageAccountTable.value] as num?)?.toDouble() ?? 0),
    );

    return total;
  }

  // ─── Total patrimoine ─────────────────────────────────────────────────────

  Future<double> getPatrimoineOwned() async {
    final userId = _requireUserId();

    final liquidity = await _supabase
        .from(UserLiquidityAccountTable.tableName)
        .select(UserLiquidityAccountTable.amount)
        .eq(UserLiquidityAccountTable.userId, userId);

    final savings = await _supabase
        .from(UserSavingsAccountTable.tableName)
        .select(
          '${UserSavingsAccountTable.principal}, ${UserSavingsAccountTable.interest}',
        )
        .eq(UserSavingsAccountTable.userId, userId);

    double total = 0.0;

    total += liquidity.fold<double>(
      0.0,
      (sum, row) =>
          sum +
          ((row[UserLiquidityAccountTable.amount] as num?)?.toDouble() ?? 0),
    );

    total += savings.fold<double>(
      0.0,
      (sum, row) =>
          sum +
          ((row[UserSavingsAccountTable.principal] as num?)?.toDouble() ?? 0) +
          ((row[UserSavingsAccountTable.interest] as num?)?.toDouble() ?? 0),
    );

    total += await _investmentService.getUserInvestmentsTotalValue();

    return total;
  }

  // ─── Présence des comptes ─────────────────────────────────────────────────

  Future<bool> hasLiquidityAccounts() => _hasAccounts(
    UserLiquidityAccountTable.tableName,
    UserLiquidityAccountTable.id,
  );

  Future<bool> hasSavingsAccounts() => _hasAccounts(
    UserSavingsAccountTable.tableName,
    UserSavingsAccountTable.id,
  );

  Future<bool> hasInvestmentAccounts() => _hasAccounts(
    UserInvestmentAccountTable.tableName,
    UserInvestmentAccountTable.id,
  );

  Future<bool> hasAdvantageAccounts() => _hasAccounts(
    UserAdvantageAccountTable.tableName,
    UserAdvantageAccountTable.id,
  );

  Future<bool> _hasAccounts(String table, String idColumn) async {
    final userId = _requireUserId();
    final response = await _supabase
        .from(table)
        .select(idColumn)
        .eq(UserLiquidityAccountTable.userId, userId)
        .limit(1);
    return response.isNotEmpty;
  }

  // ─── Catégories ───────────────────────────────────────────────────────────

  Future<List<PatrimoineCategory>> getPatrimoineCategories() async {
    final response = await _supabase
        .from(PatrimoineCategoryTable.tableName)
        .select(
          '${PatrimoineCategoryTable.id}, ${PatrimoineCategoryTable.name}, ${PatrimoineCategoryTable.label}',
        )
        .order(PatrimoineCategoryTable.name);

    return response
        .map(
          (item) => PatrimoineCategory(
            id: item[PatrimoineCategoryTable.id] as int,
            name: item[PatrimoineCategoryTable.name] as String,
            label: item[PatrimoineCategoryTable.label] as String? ?? '',
          ),
        )
        .toList();
  }

  // ─── Total déposé ─────────────────────────────────────────────────────────

  Future<double> getTotalDeposed() async {
    _requireUserId();

    final liquidityAccounts = await LiquidityAccountService()
        .getUserLiquidityAccounts();
    final savingsAccounts = await SavingsAccountService()
        .getUserSavingsAccounts();
    final investmentAccounts = await InvestmentService()
        .getUserInvestmentAccounts();
    final advantageAccounts = await AdvantageService()
        .getUserAdvantageAccounts();

    return [
      liquidityAccounts.fold<double>(0.0, (sum, a) => sum + a.amount),
      savingsAccounts.fold<double>(0.0, (sum, a) => sum + a.principal),
      investmentAccounts.fold<double>(
        0.0,
        (sum, a) => sum + a.cumulativeDeposits,
      ),
      advantageAccounts.fold<double>(0.0, (sum, a) => sum + a.value),
    ].fold<double>(0.0, (sum, subtotal) => sum + subtotal);
  }

  Future<double> getTotalOwnedCapital() async {
    final userId = _requireUserId();

    // ─────────────────────────────────────────────
    // LIQUIDITÉS (compte courant / cash dispo)
    // ─────────────────────────────────────────────
    final liquidity = await _supabase
        .from(UserLiquidityAccountTable.tableName)
        .select(UserLiquidityAccountTable.amount)
        .eq(UserLiquidityAccountTable.userId, userId);

    final liquidityTotal = liquidity.fold<double>(
      0.0,
      (sum, row) =>
          sum +
          ((row[UserLiquidityAccountTable.amount] as num?)?.toDouble() ?? 0),
    );

    // ─────────────────────────────────────────────
    // ÉPARGNE (uniquement capital, sans intérêts)
    // ─────────────────────────────────────────────
    final savings = await _supabase
        .from(UserSavingsAccountTable.tableName)
        .select(UserSavingsAccountTable.principal)
        .eq(UserSavingsAccountTable.userId, userId);

    final savingsTotal = savings.fold<double>(
      0.0,
      (sum, row) =>
          sum +
          ((row[UserSavingsAccountTable.principal] as num?)?.toDouble() ?? 0),
    );

    // ─────────────────────────────────────────────
    // INVESTISSEMENTS (uniquement dépôts versés)
    // ─────────────────────────────────────────────
    final investments = await _supabase
        .from(UserInvestmentAccountTable.tableName)
        .select(UserInvestmentAccountTable.totalContribution)
        .eq(UserInvestmentAccountTable.userId, userId);

    final investmentTotal = investments.fold<double>(
      0.0,
      (sum, row) =>
          sum +
          ((row[UserInvestmentAccountTable.totalContribution] as num?)
                  ?.toDouble() ??
              0),
    );

    // ─────────────────────────────────────────────
    // AVANTAGES SALARIÉS (exclus ici volontairement)
    // ─────────────────────────────────────────────

    final totalOwnedCapital = liquidityTotal + savingsTotal + investmentTotal;

    return totalOwnedCapital;
  }

  /// Calcule le capital total investi par l'utilisateur
  /// en additionnant les dépôts cumulés de tous ses comptes d'investissement.
  Future<double> getTotalInvestedCapital() async {
    final accounts = await _investmentService.getUserInvestmentAccounts();

    return accounts.fold<double>(
      0.0,
      (sum, account) => sum + account.cumulativeDeposits,
    );
  }

  /// Calcule la valeur totale du portefeuille en additionnant
  /// la valorisation (amount) de tous les comptes d'investissement.
  Future<double> getTotalPortfolioValue() {
    return _investmentService.getTotalPortfolioValue();
  }

  /// Calcule le patrimoine net :
  /// Somme des liquidités + Principal épargne + Capital investi
  Future<double> getNetPatrimoine() async {
    final userId = _requireUserId();

    // 1. Liquidités (Comptes espèces)
    final liquidity = await _supabase
        .from(UserLiquidityAccountTable.tableName)
        .select(UserLiquidityAccountTable.amount)
        .eq(UserLiquidityAccountTable.userId, userId);

    final liquidityTotal = liquidity.fold<double>(
      0.0,
      (sum, row) =>
          sum +
          ((row[UserLiquidityAccountTable.amount] as num?)?.toDouble() ?? 0),
    );

    // 2. Épargne (Montant déposé / principal uniquement)
    final savings = await _supabase
        .from(UserSavingsAccountTable.tableName)
        .select(UserSavingsAccountTable.principal)
        .eq(UserSavingsAccountTable.userId, userId);

    final savingsTotal = savings.fold<double>(
      0.0,
      (sum, row) =>
          sum +
          ((row[UserSavingsAccountTable.principal] as num?)?.toDouble() ?? 0),
    );

    // 3. Investissement (Capital net investi)
    final investedTotal = await getTotalInvestedCapital();

    return liquidityTotal + savingsTotal + investedTotal;
  }
}
