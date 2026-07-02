import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

    debugPrint('========================================');
    debugPrint('getBanksForLiquiditySource');
    debugPrint('userId: $userId');
    debugPrint('categoryId: $categoryId');
    debugPrint('liquidityCategoryId: $liquidityCategoryId');

    // ----------------------------------------
    // 1. Récupération des comptes existants
    // ----------------------------------------

    final existingAccounts = await _supabase
        .from(UserLiquidityAccountTable.tableName)
        .select(UserLiquidityAccountTable.liquiditySourceId)
        .eq(UserLiquidityAccountTable.userId, userId);

    debugPrint('existingAccounts: $existingAccounts');

    final liquiditySourceIds = existingAccounts
        .map<int>((e) => e[UserLiquidityAccountTable.liquiditySourceId] as int)
        .toList();

    debugPrint('liquiditySourceIds: $liquiditySourceIds');

    // ----------------------------------------
    // 2. Récupération des banques déjà utilisées
    // ----------------------------------------

    final Set<int> existingBankIds = {};

    if (liquiditySourceIds.isNotEmpty) {
      final usedSources = await _supabase
          .from(LiquiditySourceTable.tableName)
          .select('${LiquiditySourceTable.id}, ${LiquiditySourceTable.bankId}')
          .inFilter(LiquiditySourceTable.id, liquiditySourceIds);

      debugPrint('usedSources: $usedSources');

      existingBankIds.addAll(
        usedSources.map<int>((e) => e[LiquiditySourceTable.bankId] as int),
      );
    }

    debugPrint('existingBankIds: $existingBankIds');

    // ----------------------------------------
    // 3. Récupération des banques disponibles
    // ----------------------------------------

    final response = await _supabase
        .from(LiquiditySourceTable.tableName)
        .select('${LiquiditySourceTable.bankId}, $_selectBankNested')
        .eq(LiquiditySourceTable.categoryId, categoryId)
        .eq(LiquiditySourceTable.liquidityCategoryId, liquidityCategoryId);

    debugPrint('raw response: $response');

    // ----------------------------------------
    // 4. Filtrage des banques déjà utilisées
    // ----------------------------------------

    final filteredResponse = response.where((item) {
      final bankId = item[LiquiditySourceTable.bankId] as int;

      final alreadyExists = existingBankIds.contains(bankId);

      debugPrint('Checking bankId=$bankId -> alreadyExists=$alreadyExists');

      return !alreadyExists;
    }).toList();

    debugPrint('filteredResponse: $filteredResponse');

    // ----------------------------------------
    // 5. Mapping final
    // ----------------------------------------

    final banks = filteredResponse.map<Bank>(_bankFromNested).toList();

    debugPrint('banks result count: ${banks.length}');
    debugPrint('banks: $banks');
    debugPrint('========================================');

    return banks;
  }

  Future<List<Bank>> getBanksForSavingsSource({
    required int categoryId,
    required int savingsCategoryId,
  }) async {
    final response = await _supabase
        .from(SavingsSourceTable.tableName)
        .select('${SavingsSourceTable.bankId}, $_selectBankNested')
        .eq(SavingsSourceTable.categoryId, categoryId)
        .eq(SavingsSourceTable.savingsCategoryId, savingsCategoryId);

    return response.map<Bank>(_bankFromNested).toList();
  }

  Future<List<Bank>> getBanksForInvestmentSource({
    required int categoryId,
    required int investmentCategoryId,
  }) async {
    debugPrint('========================================');
    debugPrint('getBanksForInvestmentSource');
    debugPrint('categoryId: $categoryId');
    debugPrint('investmentCategoryId: $investmentCategoryId');

    try {
      debugPrint('----------------------------------------');
      debugPrint('TABLE: ${InvestmentSourceTable.tableName}');
      debugPrint('SELECT: ${InvestmentSourceTable.bankId}, $_selectBankNested');

      final response = await _supabase
          .from(InvestmentSourceTable.tableName)
          .select('${InvestmentSourceTable.bankId}, $_selectBankNested')
          // ⚠️ Vérifie bien cette ligne
          .eq(InvestmentSourceTable.categoryId, categoryId)
          // ⚠️ Avant tu filtrais deux fois categoryId
          .eq(InvestmentSourceTable.investmentCategoryId, investmentCategoryId);

      debugPrint('----------------------------------------');
      debugPrint('RAW RESPONSE: $response');
      debugPrint('RESPONSE LENGTH: ${response.length}');

      final banks = response.map<Bank>((item) {
        debugPrint('----------------------------------------');
        debugPrint('ITEM: $item');

        final bankId = item[InvestmentSourceTable.bankId];

        debugPrint('bankId: $bankId');

        final bank = _bankFromNested(item);

        debugPrint('BANK RESULT: $bank');

        return bank;
      }).toList();

      debugPrint('----------------------------------------');
      debugPrint('FINAL BANKS COUNT: ${banks.length}');
      debugPrint('FINAL BANKS: $banks');

      debugPrint('========================================');

      return banks;
    } catch (e, stackTrace) {
      debugPrint('----------------------------------------');
      debugPrint('ERROR getBanksForInvestmentSource');
      debugPrint('error: $e');
      debugPrint('stackTrace: $stackTrace');
      debugPrint('========================================');

      rethrow;
    }
  }
}
