// lib/services/patrimoine_wizard_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/database_tables.dart';
import '../models/patrimoine/patrimoine_category.dart';
import '../models/source_item.dart';
import '../models/bank.dart';

class PatrimoineWizardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static final PatrimoineWizardService _instance =
  PatrimoineWizardService._internal();
  factory PatrimoineWizardService() => _instance;
  PatrimoineWizardService._internal();

  Future<List<PatrimoineCategory>> getPatrimoineCategories() async {
    try {
      final response = await _supabase
          .from(DatabaseTables.patrimoineCategory)
          .select('id, name, label')
          .order('name');

      return response.map((item) => PatrimoineCategory(
        id: item['id'] as int,
        name: item['name'] as String,
        label: item['label'] as String? ?? '',
      )).toList();
    } catch (e) {
      print('Erreur getPatrimoineCategories: $e');
      rethrow;
    }
  }

// Dans patrimoine_wizard_service.dart
  Future<List<SourceItem>> getSourcesForCategory(
      PatrimoineCategory category
      ) async {
    try {
      final categoryName = category.name.toLowerCase();
      print('🔍 Service: recherche pour catégorie "$categoryName" (ID: ${category.id})');

      if (categoryName.contains('liquid') || categoryName.contains('cash')) {
        print('📦 Chargement depuis liquidity_source');
        final response = await _supabase
            .from(DatabaseTables.liquiditySource)
            .select('id, name, type, bank_id, category_id')
            .eq('category_id', category.id)
            .order('name');

        print('✅ Réponse: ${response.length} éléments');
        return response.map((item) =>
            SourceItem.fromLiquiditySource(item)).toList();

      } else if (categoryName.contains('saving') ||
          categoryName.contains('épargne') ||
          categoryName.contains('epargne')) {
        print('📦 Chargement depuis savings_category');
        final response = await _supabase
            .from('savings_category')
            .select('id, name, interest_rate, ceiling')
            .order('name');

        print('✅ Réponse: ${response.length} éléments');
        print('📋 Détails de la réponse: $response');

        return response.map((item) =>
            SourceItem.fromSavingsCategory(item)).toList();

      } else {
        print('⚠️ Catégorie non gérée: ${category.name}');
        return [];
      }
    } catch (e) {
      print('❌ Erreur getSourcesForCategory: $e');
      rethrow;
    }
  }

  Future<List<Bank>> getBanks() async {
    try {
      final response = await _supabase
          .from(DatabaseTables.banks)
          .select('id, name')
          .order('name');

      return response.map((item) => Bank(
        id: item['id'] as int,
        name: item['name'] as String,
      )).toList();
    } catch (e) {
      print('Erreur getBanks: $e');
      rethrow;
    }
  }

  Future<List<Bank>> getBanksForLiquiditySource(SourceItem source) async {
    if (source.bankId == null) return [];

    final response = await _supabase
        .from(DatabaseTables.banks)
        .select('id, name')
        .eq('id', source.bankId!)
        .single();

    return [
      Bank(
        id: response['id'] as int,
        name: response['name'] as String,
      )
    ];
  }

  Future<List<Bank>> getBanksForSavingsSource({
    required int categoryId,
    required int savingsCategoryId,
  }) async {
    final response = await _supabase
        .from('savings_source')
        .select('bank_id, banks ( id, name )')
        .eq('category_id', categoryId)
        .eq('savings_category_id', savingsCategoryId);

    return response
        .map<Bank>((item) => Bank(
      id: item['banks']['id'] as int,
      name: item['banks']['name'] as String,
    ))
        .toList();
  }
}