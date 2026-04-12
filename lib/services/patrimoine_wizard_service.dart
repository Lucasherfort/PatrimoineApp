import 'package:supabase_flutter/supabase_flutter.dart';
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

  // ─────────────────────────────────────────────
  // 🔐 Utils
  // ─────────────────────────────────────────────

  String _requireUserId() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }
    return user.id;
  }

  Future<List<PatrimoineCategory>> getPatrimoineCategories() async {
    try {
      final response = await _supabase
          .from(DatabaseTables.patrimoineCategory)
          .select('id, name, label')
          .order('name');

      return response
          .map(
            (item) => PatrimoineCategory(
              id: item['id'] as int,
              name: item['name'] as String,
              label: item['label'] as String? ?? '',
            ),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SourceItem>> getSourcesForCategory(
    PatrimoineCategory category,
  ) async {
    try {
      final categoryName = category.name;

      if (categoryName == 'Cash') {
        final response = await _supabase
            .from(DatabaseTables.liquidityCategory)
            .select('id, name');

        return response
            .map((item) => SourceItem.fromLiquiditySource(item))
            .toList();
      } else if (categoryName.contains('Saving')) {
        final response = await _supabase
            .from(DatabaseTables.savingsCategory)
            .select('id, name, interest_rate, ceiling');

        return response
            .map((item) => SourceItem.fromSavingsCategory(item))
            .toList();
      } else if (categoryName.contains('Investments')) {
        final response = await _supabase
            .from(DatabaseTables.investmentCategory)
            .select('id, name');

        return response
            .map((item) => SourceItem.fromInvestmentCategory(item))
            .toList();
      } else if (categoryName.contains('Benefits')) {
        // 🔹 Nouvelle logique pour les avantages
        final response = await _supabase
            .from(DatabaseTables.advantageCategory)
            .select('id, name');

        return response
            .map((item) => SourceItem.fromAdvantageCategory(item))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Bank>> getBanks() async {
    try {
      final response = await _supabase
          .from(DatabaseTables.banks)
          .select('id, name')
          .order('name');

      return response
          .map(
            (item) => Bank(id: item['id'] as int, name: item['name'] as String),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Bank>> getBanksForLiquiditySource({
    required int categoryId,
    required int liquidityCategoryId,
  }) async {
    final userId = _requireUserId();

    try {
      // 1. Récupérer les liquidity_source déjà utilisés par l'utilisateur
      final existingAccounts = await _supabase
          .from(DatabaseTables.userLiquidityAccounts)
          .select('liquidity_source_id')
          .eq('user_id', userId);

      final liquiditySourceIds = existingAccounts
          .map<int>((e) => e['liquidity_source_id'] as int)
          .toList();

      // 2. Récupérer les bank_id déjà utilisés
      List<int> existingBankIds = [];

      if (liquiditySourceIds.isNotEmpty) {
        final usedSources = await _supabase
            .from(DatabaseTables.liquiditySource)
            .select('id, bank_id')
            .inFilter('id', liquiditySourceIds);

        existingBankIds = usedSources
            .map<int>((e) => e['bank_id'] as int)
            .toSet()
            .toList();
      }

      // 3. Récupérer les liquidity sources compatibles
      final response = await _supabase
          .from(DatabaseTables.liquiditySource)
          .select('id, bank_id, banks (id, name)')
          .eq('category_id', categoryId)
          .eq('liquidity_category_id', liquidityCategoryId);

      // 4. Filtrer les banques déjà utilisées
      final filtered = response.where((item) {
        final bankId = item['bank_id'] as int;
        return !existingBankIds.contains(bankId);
      }).toList();

      // 5. Mapping vers Bank
      return filtered
          .map<Bank>(
            (item) => Bank(
              id: item['banks']['id'] as int,
              name: item['banks']['name'] as String,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch available banks: $e');
    }
  }

  Future<List<Bank>> getBanksForSavingsSource({
    required int categoryId,
    required int savingsCategoryId,
  }) async {
    final response = await _supabase
        .from(DatabaseTables.savingsSource)
        .select('bank_id, banks ( id, name )')
        .eq('category_id', categoryId)
        .eq('savings_category_id', savingsCategoryId);

    return response
        .map<Bank>(
          (item) => Bank(
            id: item['banks']['id'] as int,
            name: item['banks']['name'] as String,
          ),
        )
        .toList();
  }

  // Récupère la liste des banques selon le type d'investissement
  Future<List<Bank>> getBanksForInvestmentSource({
    required int categoryId,
    required int investmentCategoryId,
  }) async {
    final response = await _supabase
        .from(DatabaseTables.investmentSource)
        .select('bank_id, banks ( id, name )')
        .eq('category_id', categoryId)
        .eq('investment_category_id', investmentCategoryId);

    return response
        .map<Bank>(
          (item) => Bank(
            id: item['banks']['id'] as int,
            name: item['banks']['name'] as String,
          ),
        )
        .toList();
  }

  // Récupère la liste des fournisseurs selon le type d'avantage
  Future<List<Provider>> getProvidersForAdvantageSource({
    required int categoryId,
    required int advantageCategoryId,
  }) async {
    final response = await _supabase
        .from(DatabaseTables.advantageSource)
        .select('provider_id, advantage_provider ( id, name )')
        .eq('category_id', categoryId)
        .eq('advantage_category_id', advantageCategoryId);

    return response.map<Provider>((item) {
      final provider = item['advantage_provider'];

      return Provider(
        id: provider['id'] as int,
        name: provider['name'] as String,
      );
    }).toList();
  }
}
