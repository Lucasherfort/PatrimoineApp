import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/database_columns.dart';
import '../bdd/database_tables.dart';
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
    ${BankColumns.id},
    ${BankColumns.name}
  ''';

  static const _selectBankNested =
      '''
    ${DatabaseTables.banks} (
      ${BankColumns.id},
      ${BankColumns.name}
    )
  ''';

  static const _selectProviderNested =
      '''
    ${AdvantageSourceColumns.providerId},
    ${DatabaseTables.advantageProvider} (
      ${AdvantageProviderColumns.id},
      ${AdvantageProviderColumns.name}
    )
  ''';

  // ─── Utils ────────────────────────────────────────────────────────────────

  String _requireUserId() {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');
    return user.id;
  }

  Bank _bankFromNested(Map<String, dynamic> item) => Bank(
    id: item[DatabaseTables.banks][BankColumns.id] as int,
    name: item[DatabaseTables.banks][BankColumns.name] as String,
  );

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

  Future<List<SourceItem>> getSourcesForCategory(
    PatrimoineCategory category,
  ) async {
    final categoryName = category.name;

    if (categoryName == 'Cash') {
      final response = await _supabase
          .from(DatabaseTables.liquidityCategory)
          .select(
            '${LiquidityCategoryColumns.id}, ${LiquidityCategoryColumns.name}',
          );
      return response
          .map((item) => SourceItem.fromLiquiditySource(item))
          .toList();
    }

    if (categoryName.contains('Saving')) {
      final response = await _supabase
          .from(DatabaseTables.savingsCategory)
          .select(
            '${SavingsCategoryColumns.id}, ${SavingsCategoryColumns.name}, ${SavingsCategoryColumns.interestRate}, ${SavingsCategoryColumns.ceiling}',
          );
      return response
          .map((item) => SourceItem.fromSavingsCategory(item))
          .toList();
    }

    if (categoryName.contains('Investments')) {
      final response = await _supabase
          .from(DatabaseTables.investmentCategory)
          .select(
            '${InvestmentCategoryColumns.id}, ${InvestmentCategoryColumns.name}',
          );
      return response
          .map((item) => SourceItem.fromInvestmentCategory(item))
          .toList();
    }

    if (categoryName.contains('Benefits')) {
      final response = await _supabase
          .from(DatabaseTables.advantageCategory)
          .select(
            '${AdvantageCategoryColumns.id}, ${AdvantageCategoryColumns.name}',
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
        .from(DatabaseTables.banks)
        .select(_selectBankWithId)
        .order(BankColumns.name);

    return response
        .map(
          (item) => Bank(
            id: item[BankColumns.id] as int,
            name: item[BankColumns.name] as String,
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
        .from(DatabaseTables.userLiquidityAccounts)
        .select(LiquidityUserAccountColumns.liquiditySourceId)
        .eq(LiquidityUserAccountColumns.userId, userId);

    final liquiditySourceIds = existingAccounts
        .map<int>(
          (e) => e[LiquidityUserAccountColumns.liquiditySourceId] as int,
        )
        .toList();

    final Set<int> existingBankIds = {};

    if (liquiditySourceIds.isNotEmpty) {
      final usedSources = await _supabase
          .from(DatabaseTables.liquiditySource)
          .select(
            '${LiquiditySourceColumns.id}, ${LiquiditySourceColumns.bankId}',
          )
          .inFilter(LiquiditySourceColumns.id, liquiditySourceIds);

      existingBankIds.addAll(
        usedSources.map<int>((e) => e[LiquiditySourceColumns.bankId] as int),
      );
    }

    final response = await _supabase
        .from(DatabaseTables.liquiditySource)
        .select('${LiquiditySourceColumns.bankId}, $_selectBankNested')
        .eq(LiquiditySourceColumns.liquidityCategoryId, categoryId)
        .eq(LiquiditySourceColumns.liquidityCategoryId, liquidityCategoryId);

    return response
        .where(
          (item) => !existingBankIds.contains(
            item[LiquiditySourceColumns.bankId] as int,
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
        .from(DatabaseTables.savingsSource)
        .select('${SavingsSourceColumns.bankId}, $_selectBankNested')
        .eq(SavingsSourceColumns.categoryId, categoryId)
        .eq(SavingsSourceColumns.savingsCategoryId, savingsCategoryId);

    return response.map<Bank>(_bankFromNested).toList();
  }

  Future<List<Bank>> getBanksForInvestmentSource({
    required int categoryId,
    required int investmentCategoryId,
  }) async {
    final response = await _supabase
        .from(DatabaseTables.investmentSource)
        .select('${InvestmentSourceColumns.bankId}, $_selectBankNested')
        .eq(InvestmentSourceColumns.categoryId, categoryId)
        .eq(InvestmentSourceColumns.categoryId, investmentCategoryId);

    return response.map<Bank>(_bankFromNested).toList();
  }

  // ─── Fournisseurs ─────────────────────────────────────────────────────────

  Future<List<Provider>> getProvidersForAdvantageSource({
    required int categoryId,
    required int advantageCategoryId,
  }) async {
    final response = await _supabase
        .from(DatabaseTables.advantageSource)
        .select(_selectProviderNested)
        .eq(AdvantageSourceColumns.advantageCategoryId, categoryId)
        .eq(AdvantageSourceColumns.advantageCategoryId, advantageCategoryId);

    return response.map<Provider>((item) {
      final provider =
          item[DatabaseTables.advantageProvider] as Map<String, dynamic>;
      return Provider(
        id: provider[AdvantageProviderColumns.id] as int,
        name: provider[AdvantageProviderColumns.name] as String,
      );
    }).toList();
  }
}
