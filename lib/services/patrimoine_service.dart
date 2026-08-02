import 'package:patrimoine360/services/savings_account_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/patrimoine_category_table.dart';
import '../bdd/user_investment_account_table.dart';
import '../bdd/user_liquidity_account_table.dart';
import '../bdd/user_savings_account_table.dart';
import '../models/investments/user_investment_account_view.dart';
import '../models/patrimoine/patrimoine_category.dart';
import '../models/patrimoine/patrimonial_indicator.dart';
import '../models/investments/estimated_gains_result.dart';
import 'financial_profile_manager.dart';
import 'investment_service.dart';
import 'liquidity_service.dart';
import 'settings_service.dart';

class PatrimoineService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static final PatrimoineService _instance = PatrimoineService._internal();
  factory PatrimoineService() => _instance;
  PatrimoineService._internal();

  final LiquidityService _liquidityService = LiquidityService();
  final SavingsAccountService _savingsService = SavingsAccountService();
  final InvestmentService _investmentService = InvestmentService();
  final SettingsService _settingsService = SettingsService();
  final FinancialProfileManager _financialProfileManager =
      FinancialProfileManager();

  // ─── Utils ────────────────────────────────────────────────────────────────

  String _requireUserId() {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');
    return user.id;
  }

  // ─── Total patrimoine ─────────────────────────────────────────────────────

  /// Récupère la valeur totale brute du patrimoine
  Future<double> getPatrimoineGross() async {
    _requireUserId();

    final values = await Future.wait([
      _liquidityService.getTotalLiquidityValue(),
      _savingsService.getTotalSavingsValue(),
      _investmentService.getTotalPortfolioValueGross(),
    ]);

    return values.reduce((a, b) => a + b);
  }

  /// Récupère la valeur totale nette estimée du patrimoine
  Future<double> getPatrimoineNetEstimated() async {
    _requireUserId();

    final values = await Future.wait([
      _liquidityService.getTotalLiquidityValue(),
      _savingsService.getTotalSavingsValue(),
      _investmentService.getTotalPortfolioValueNet(),
    ]);

    return values.reduce((a, b) => a + b);
  }

  /// Récupère la valeur totale du patrimoine (Liquidités + Épargne + Investissements)
  /// Note: Dépend de la préférence Brut/Net actuelle
  Future<double> getPatrimoine() async {
    _requireUserId();

    final values = await Future.wait([
      _liquidityService.getTotalLiquidityValue(),
      _savingsService.getTotalSavingsValue(),
      _investmentService.getUserInvestmentsTotalValue(),
    ]);

    return values.reduce((a, b) => a + b);
  }

  // ─── Total patrimoine ─────────────────────────────────────────────────────

  /// Récupère la valeur du patrimoine détenu (Liquidités + Épargne + Investissements)
  Future<double> getPatrimoineOwned() => getPatrimoine();

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
    ]);

    final liquidityAccounts = results[0] as List;
    final savingsAccounts = results[1] as List;
    final investmentAccounts = results[2] as List;

    return [
      liquidityAccounts.fold<double>(0.0, (sum, a) => sum + a.amount),
      savingsAccounts.fold<double>(0.0, (sum, a) => sum + a.principal),
      investmentAccounts.fold<double>(
        0.0,
        (sum, a) => sum + a.cumulativeDeposits,
      ),
    ].fold<double>(0.0, (sum, subtotal) => sum + subtotal);
  }

  Future<double> getTotalOwnedCapital() async {
    _requireUserId();

    final values = await Future.wait([
      _liquidityService.getTotalLiquidityValue(),
      _savingsService.getTotalSavingsPrincipal(),
      getTotalInvestedCapital(),
    ]);

    return values[0] + values[1] + values[2];
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

  /// Récupère le montant total des gains annuels estimés du patrimoine (investissements)
  Future<double> getEstimatedAnnualInvestmentGains() {
    return _investmentService.getTotalEstimatedAnnualGains();
  }

  /// Récupère les détails des gains annuels estimés
  Future<EstimatedGainsResult> getDetailedEstimatedAnnualGains() {
    return _investmentService.getDetailedEstimatedAnnualGains();
  }

  /// Récupère tous les comptes d'investissement avec leurs prix
  Future<List<UserInvestmentAccountView>>
  getInvestmentAccountsForUserWithPrices() {
    return _investmentService.getInvestmentAccountsForUserWithPrices();
  }

  /// Proxy pour calculer le rendement d'un compte spécifique
  double? calculateAnnualizedReturnForAccount(UserInvestmentAccountView acc) {
    return _investmentService.calculateAnnualizedReturn(
      totalContribution: acc.totalContribution,
      currentValuation: acc.amount,
      openedAt: acc.openedAt,
    );
  }

  /// Calcule l'indicateur "Point de croisement"
  /// Gains annuels >= Investissement annuel
  Future<PatrimonialIndicator> getCrossingPointIndicator() async {
    final double gains = await getEstimatedAnnualInvestmentGains();
    final double? monthlyInvestment = await _settingsService
        .getMonthlyInvestment();
    final double annualInvestment = (monthlyInvestment ?? 0) * 12;

    final bool isCalculable = annualInvestment > 0;
    final double progression = isCalculable
        ? (gains / annualInvestment) * 100
        : 0;

    return PatrimonialIndicator(
      name: "Point de croisement",
      currentValue: gains,
      targetValue: annualInvestment,
      progression: progression,
      isReached: isCalculable && gains >= annualInvestment,
      isCalculable: isCalculable,
    );
  }

  /// Calcule l'indicateur "Chiffre de croisière"
  /// Progression du patrimoine actuel vers le patrimoine cible de retraite
  Future<PatrimonialIndicator> getCruisingSpeedIndicator() async {
    final double currentWealth = await getPatrimoineGross();

    // Récupération des paramètres de retraite
    final double incomeDesired =
        _financialProfileManager.retirementDesiredIncome;
    final double pensionEstimated =
        _financialProfileManager.retirementEstimatedPension;
    final double swr = _financialProfileManager.retirementSwr;

    final double incomeToFinance = (incomeDesired - pensionEstimated).clamp(
      0.0,
      double.infinity,
    );
    final double targetWealth = incomeToFinance > 0
        ? incomeToFinance / (swr / 100)
        : 0.0;

    final bool isCalculable = incomeDesired > 0;

    // Si l'objectif est 0 (pension > revenu), progression 100%
    final double progression = targetWealth > 0
        ? (currentWealth / targetWealth) * 100
        : (isCalculable ? 100.0 : 0.0);

    return PatrimonialIndicator(
      name: "Chiffre de croisière",
      currentValue: currentWealth,
      targetValue: targetWealth,
      progression: progression.clamp(0.0, 100.0),
      isReached: isCalculable && currentWealth >= targetWealth,
      isCalculable: isCalculable,
    );
  }

  /// Calcule le patrimoine net :
  /// Somme des liquidités + Principal épargne + Capital investi
  Future<double> getNetPatrimoine() async {
    _requireUserId();

    final values = await Future.wait([
      _liquidityService.getTotalLiquidityValue(),
      _savingsService.getTotalSavingsPrincipal(),
      getTotalInvestedCapital(),
    ]);

    return values[0] + values[1] + values[2];
  }
}
