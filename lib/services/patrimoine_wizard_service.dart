import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/advantage_category_table.dart';
import '../bdd/advantage_provider_table.dart';
import '../bdd/advantage_source_table.dart';
import '../bdd/banks_table.dart';
import '../bdd/investment_category_table.dart';
import '../bdd/investment_source_table.dart';
import '../bdd/liquidity_category_table.dart';
import '../bdd/liquidity_source_table.dart';
import '../bdd/patrimoine_category_table.dart';
import '../bdd/savings_category_table.dart';
import '../bdd/savings_source_table.dart';
import '../bdd/user_liquidity_account_table.dart';
import '../models/patrimoine/patrimoine_category.dart';
import '../models/source_item.dart';
import '../models/bank.dart';
import '../models/advantage/provider.dart';

class PatrimoineWizardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static final PatrimoineWizardService _instance =
      PatrimoineWizardService._internal();
  factory PatrimoineWizardService() => _instance;
  PatrimoineWizardService._internal();

  // ─── Sélects ──────────────────────────────────────────────────────────────

  static const _selectBankWithId =
      '''
    ${BanksTable.id},
    ${BanksTable.name}
  ''';

  static const _selectBankNested =
      '''
    ${BanksTable.tableName} (
      ${BanksTable.id},
      ${BanksTable.name}
    )
  ''';

  static const _selectProviderNested =
      '''
    ${AdvantageSourceTable.providerId},
    ${AdvantageProviderTable.tableName} (
      ${AdvantageProviderTable.id},
      ${AdvantageProviderTable.name}
    )
  ''';

  // ─── Utils ────────────────────────────────────────────────────────────────

  String _requireUserId() {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');
    return user.id;
  }

  Bank _bankFromNested(Map<String, dynamic> item) => Bank(
    id: item[BanksTable.tableName][BanksTable.id] as int,
    name: item[BanksTable.tableName][BanksTable.name] as String,
  );

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

  Future<List<SourceItem>> getSourcesForCategory(
    PatrimoineCategory category,
  ) async {
    final categoryName = category.name;

    if (categoryName == 'Cash') {
      final response = await _supabase
          .from(LiquidityCategoryTable.tableName)
          .select(
            '${LiquidityCategoryTable.id}, ${LiquidityCategoryTable.name}',
          );
      return response
          .map((item) => SourceItem.fromLiquiditySource(item))
          .toList();
    }

    if (categoryName.contains('Saving')) {
      final response = await _supabase
          .from(SavingsCategoryTable.tableName)
          .select(
            '${SavingsCategoryTable.id}, ${SavingsCategoryTable.name}, ${SavingsCategoryTable.interestRate}, ${SavingsCategoryTable.ceiling}',
          );
      return response
          .map((item) => SourceItem.fromSavingsCategory(item))
          .toList();
    }

    if (categoryName.contains('Investments')) {
      final response = await _supabase
          .from(InvestmentCategoryTable.tableName)
          .select(
            '${InvestmentCategoryTable.id}, ${InvestmentCategoryTable.name}',
          );
      return response
          .map((item) => SourceItem.fromInvestmentCategory(item))
          .toList();
    }

    if (categoryName.contains('Benefits')) {
      final response = await _supabase
          .from(AdvantageCategoryTable.tableName)
          .select(
            '${AdvantageCategoryTable.id}, ${AdvantageCategoryTable.name}',
          );
      return response
          .map((item) => SourceItem.fromAdvantageCategory(item))
          .toList();
    }

    return [];
  }

  // ─── Banques ──────────────────────────────────────────────────────────────

  Future<List<Bank>> getBanks() async {
    final response = await _supabase
        .from(BanksTable.tableName)
        .select(_selectBankWithId)
        .order(BanksTable.name);

    return response
        .map(
          (item) => Bank(
            id: item[BanksTable.id] as int,
            name: item[BanksTable.name] as String,
          ),
        )
        .toList();
  }

  Future<List<Bank>> getBanksForLiquiditySource({
    required int categoryId,
    required int liquidityCategoryId,
  }) async {
    final userId = _requireUserId();

    final existingAccounts = await _supabase
        .from(UserLiquidityAccountTable.tableName)
        .select(UserLiquidityAccountTable.liquiditySourceId)
        .eq(UserLiquidityAccountTable.userId, userId);

    final liquiditySourceIds = existingAccounts
        .map<int>(
          (e) => e[UserLiquidityAccountTable.liquiditySourceId] as int,
        )
        .toList();

    final Set<int> existingBankIds = {};

    if (liquiditySourceIds.isNotEmpty) {
      final usedSources = await _supabase
          .from(LiquiditySourceTable.tableName)
          .select(
            '${LiquiditySourceTable.id}, ${LiquiditySourceTable.bankId}',
          )
          .inFilter(LiquiditySourceTable.id, liquiditySourceIds);

      existingBankIds.addAll(
        usedSources.map<int>((e) => e[LiquiditySourceTable.bankId] as int),
      );
    }

    final response = await _supabase
        .from(LiquiditySourceTable.tableName)
        .select('${LiquiditySourceTable.bankId}, $_selectBankNested')
        .eq(LiquiditySourceTable.liquidityCategoryId, categoryId)
        .eq(LiquiditySourceTable.liquidityCategoryId, liquidityCategoryId);

    return response
        .where(
          (item) => !existingBankIds.contains(
            item[LiquiditySourceTable.bankId] as int,
          ),
        )
        .map<Bank>(_bankFromNested)
        .toList();
  }

  Future<List<Bank>> getBanksForSavingsSource({
    required int categoryId,
    required int savingsCategoryId,
  }) async {
    final response = await _supabase
        .from(SavingsCategoryTable.tableName)
        .select('${SavingsSourceTable.bankId}, $_selectBankNested')
        .eq(SavingsSourceTable.categoryId, categoryId)
        .eq(SavingsSourceTable.savingsCategoryId, savingsCategoryId);

    return response.map<Bank>(_bankFromNested).toList();
  }

  Future<List<Bank>> getBanksForInvestmentSource({
    required int categoryId,
    required int investmentCategoryId,
  }) async {
    final response = await _supabase
        .from(InvestmentSourceTable.tableName)
        .select('${InvestmentSourceTable.bankId}, $_selectBankNested')
        .eq(InvestmentSourceTable.categoryId, categoryId)
        .eq(InvestmentSourceTable.categoryId, investmentCategoryId);

    return response.map<Bank>(_bankFromNested).toList();
  }

  // ─── Fournisseurs ─────────────────────────────────────────────────────────

  Future<List<Provider>> getProvidersForAdvantageSource({
    required int categoryId,
    required int advantageCategoryId,
  }) async {
    final response = await _supabase
        .from(AdvantageSourceTable.tableName)
        .select(_selectProviderNested)
        .eq(AdvantageSourceTable.advantageCategoryId, categoryId)
        .eq(AdvantageSourceTable.advantageCategoryId, advantageCategoryId);

    return response.map<Provider>((item) {
      final provider =
          item[AdvantageProviderTable.tableName] as Map<String, dynamic>;
      return Provider(
        id: provider[AdvantageProviderTable.id] as int,
        name: provider[AdvantageProviderTable.name] as String,
      );
    }).toList();
  }
}
