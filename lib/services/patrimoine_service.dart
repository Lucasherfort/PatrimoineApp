import 'package:patrimoine360/services/savings_account_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/database_columns.dart';
import '../bdd/database_tables.dart';
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
        .from(DatabaseTables.userLiquidityAccounts)
        .select(LiquidityAccountColumns.amount)
        .eq(LiquidityAccountColumns.userId, userId);

    final savings = await _supabase
        .from(DatabaseTables.userSavingsAccounts)
        .select(
          '${SavingsAccountColumns.principal}, ${SavingsAccountColumns.interest}',
        )
        .eq(SavingsAccountColumns.userId, userId);

    final advantage = await _supabase
        .from(DatabaseTables.userAdvantageAccount)
        .select(AdvantageAccountColumns.value)
        .eq(AdvantageAccountColumns.userId, userId);

    double total = 0.0;

    total += liquidity.fold<double>(
      0.0,
      (sum, row) =>
          sum +
          ((row[LiquidityAccountColumns.amount] as num?)?.toDouble() ?? 0),
    );

    total += savings.fold<double>(
      0.0,
      (sum, row) =>
          sum +
          ((row[SavingsAccountColumns.principal] as num?)?.toDouble() ?? 0) +
          ((row[SavingsAccountColumns.interest] as num?)?.toDouble() ?? 0),
    );

    total += await _investmentService.getUserInvestmentsTotalValue();

    total += advantage.fold<double>(
      0.0,
      (sum, row) =>
          sum + ((row[AdvantageAccountColumns.value] as num?)?.toDouble() ?? 0),
    );

    return total;
  }

  // ─── Présence des comptes ─────────────────────────────────────────────────

  Future<bool> hasLiquidityAccounts() => _hasAccounts(
    DatabaseTables.userLiquidityAccounts,
    LiquidityAccountColumns.id,
  );

  Future<bool> hasSavingsAccounts() => _hasAccounts(
    DatabaseTables.userSavingsAccounts,
    SavingsAccountColumns.id,
  );

  Future<bool> hasInvestmentAccounts() => _hasAccounts(
    DatabaseTables.userInvestmentAccount,
    InvestmentAccountColumns.id,
  );

  Future<bool> hasAdvantageAccounts() => _hasAccounts(
    DatabaseTables.userAdvantageAccount,
    AdvantageAccountColumns.id,
  );

  Future<bool> _hasAccounts(String table, String idColumn) async {
    final userId = _requireUserId();
    final response = await _supabase
        .from(table)
        .select(idColumn)
        .eq(LiquidityAccountColumns.userId, userId)
        .limit(1);
    return response.isNotEmpty;
  }

  // ─── Catégories ───────────────────────────────────────────────────────────

  Future<List<PatrimoineCategory>> getPatrimoineCategories() async {
    final response = await _supabase
        .from(DatabaseTables.patrimoineCategory)
        .select(
          '${PatrimoineCategoryColumns.id}, ${PatrimoineCategoryColumns.name}, ${PatrimoineCategoryColumns.label}',
        )
        .order(PatrimoineCategoryColumns.name);

    return response
        .map(
          (item) => PatrimoineCategory(
            id: item[PatrimoineCategoryColumns.id] as int,
            name: item[PatrimoineCategoryColumns.name] as String,
            label: item[PatrimoineCategoryColumns.label] as String? ?? '',
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
}
