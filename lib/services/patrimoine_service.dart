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
import 'liquidity_service.dart';

class PatrimoineService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static final PatrimoineService _instance = PatrimoineService._internal();
  factory PatrimoineService() => _instance;
  PatrimoineService._internal();

  final LiquidityService _liquidityService = LiquidityService();
  final SavingsAccountService _savingsService = SavingsAccountService();
  final InvestmentService _investmentService = InvestmentService();
  final AdvantageService _advantageService = AdvantageService();

  // ─── Utils ────────────────────────────────────────────────────────────────

  String _requireUserId() {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');
    return user.id;
  }

  // ─── Total patrimoine ─────────────────────────────────────────────────────

  /// Récupère la valeur totale du patrimoine (Liquidités + Épargne + Investissements + Avantages)
  Future<double> getPatrimoine() async {
    _requireUserId();

    final values = await Future.wait([
      _liquidityService.getTotalLiquidityValue(),
      _savingsService.getTotalSavingsValue(),
      _investmentService.getUserInvestmentsTotalValue(),
      _advantageService.getTotalAdvantageValue(),
    ]);

    return values.reduce((a, b) => a + b);
  }

  // ─── Total patrimoine ─────────────────────────────────────────────────────

  /// Récupère la valeur du patrimoine "détenu" en propre (Liquidités + Épargne + Investissements)
  /// Exclut les avantages salariés.
  Future<double> getPatrimoineOwned() async {
    _requireUserId();

    final values = await Future.wait([
      _liquidityService.getTotalLiquidityValue(),
      _savingsService.getTotalSavingsValue(),
      _investmentService.getUserInvestmentsTotalValue(),
    ]);

    return values.reduce((a, b) => a + b);
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

    final results = await Future.wait([
      _liquidityService.getUserLiquidityAccounts(),
      _savingsService.getUserSavingsAccounts(),
      _investmentService.getUserInvestmentAccounts(),
      _advantageService.getUserAdvantageAccounts(),
    ]);

    final liquidityAccounts = results[0] as List;
    final savingsAccounts = results[1] as List;
    final investmentAccounts = results[2] as List;
    final advantageAccounts = results[3] as List;

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

  /// Récupère la valeur totale des investissements d'un utilisateur depuis le service
  Future<double> getTotalPortfolioValue() {
    return _investmentService.getTotalPortfolioValue();
  }

  /// Calcule le patrimoine net :
  /// Somme des liquidités + Principal épargne + Capital investi
  Future<double> getNetPatrimoine() async {
    _requireUserId();

    final values = await Future.wait([
      _liquidityService.getTotalLiquidityValue(),
      _savingsService.getTotalSavingsValue(), // On veut le principal ici ? Non, l'énoncé dit "Somme des liquidités + Principal épargne + Capital investi"
    ]);

    // En fait, getNetPatrimoine a une définition spécifique : principal uniquement pour l'épargne.
    // Je vais garder les calculs spécifiques mais utiliser les services si possible.
    
    // Pour l'épargne (principal uniquement), on n'a pas encore de méthode dédiée dans SavingsAccountService.
    // Mais on peut la rajouter ou garder la requête ici.
    
    final liquidityTotal = await _liquidityService.getTotalLiquidityValue();
    
    // On va chercher le principal épargne via une nouvelle méthode ou directement.
    final savingsAccounts = await _savingsService.getUserSavingsAccounts();
    final savingsTotal = savingsAccounts.fold<double>(0.0, (sum, a) => sum + a.principal);

    // 3. Investissement (Capital net investi)
    final investedTotal = await getTotalInvestedCapital();

    return liquidityTotal + savingsTotal + investedTotal;
  }
}
