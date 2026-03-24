import 'package:patrimoine360/services/savings_account_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/database_tables.dart';
import '../models/patrimoine/patrimoine_category.dart';
import 'advantage_service.dart';
import 'investment_service.dart';
import 'liquidity_account_service.dart';

class PatrimoineService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ✅ Singleton
  static final PatrimoineService _instance = PatrimoineService._internal();
  factory PatrimoineService() => _instance;
  PatrimoineService._internal();
  final InvestmentService _investmentService = InvestmentService();

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

  // ─────────────────────────────────────────────
  // 💰 TOTAL PATRIMOINE
  // ─────────────────────────────────────────────

  Future<double> getPatrimoine() async {
    final userId = _requireUserId();

    try {
      double total = 0;

      // 🔹 Liquidité
      final liquidity = await _supabase
          .from(DatabaseTables.userLiquidityAccounts)
          .select('amount')
          .eq('user_id', userId);

      for (final row in liquidity) {
        total += (row['amount'] as num?)?.toDouble() ?? 0;
      }

      // 🔹 Épargne
      final savings = await _supabase
          .from(DatabaseTables.userSavingsAccounts)
          .select('principal, interest')
          .eq('user_id', userId);

      for (final row in savings) {
        total +=
            ((row['principal'] as num?)?.toDouble() ?? 0) +
            ((row['interest'] as num?)?.toDouble() ?? 0);
      }

      // 🔹 (Investissements
      total += await _investmentService.getUserInvestmentsTotalValue();

      // Advantage
      final advantage = await _supabase
          .from(DatabaseTables.userAdvantageAccount)
          .select('value')
          .eq('user_id', userId);

      for (final row in advantage) {
        total += ((row['value'] as num?)?.toDouble() ?? 0);
      }

      return total;
    } catch (e) {
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 📊 PRÉSENCE DES COMPTES
  // ─────────────────────────────────────────────

  Future<bool> hasLiquidityAccounts() async {
    final userId = _requireUserId();

    final response = await _supabase
        .from(DatabaseTables.userLiquidityAccounts)
        .select('id')
        .eq('user_id', userId)
        .limit(1);

    return response.isNotEmpty;
  }

  Future<bool> hasSavingsAccounts() async {
    final userId = _requireUserId();

    final response = await _supabase
        .from(DatabaseTables.userSavingsAccounts)
        .select('id')
        .eq('user_id', userId)
        .limit(1);

    return response.isNotEmpty;
  }

  Future<bool> hasInvestmentAccounts() async {
    final userId = _requireUserId();

    final response = await _supabase
        .from(DatabaseTables.userInvestmentAccount)
        .select('id')
        .eq('user_id', userId)
        .limit(1);

    return response.isNotEmpty;
  }

  Future<bool> hasAdvantageAccounts() async {
    final userId = _requireUserId();

    final response = await _supabase
        .from(DatabaseTables.userAdvantageAccount)
        .select('id')
        .eq('user_id', userId)
        .limit(1);

    return response.isNotEmpty;
  }

  // ─────────────────────────────────────────────
  // 📂 CATÉGORIES
  // ─────────────────────────────────────────────

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

  /// Calcule le total déposé (argent investi sans les gains)
  Future<double> getTotalDeposed() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0.0;

    try {
      double total = 0.0;

      // Liquidité (tout = déposé)
      final liquidityAccounts = await LiquidityAccountService()
          .getUserLiquidityAccounts();
      total += liquidityAccounts.fold<double>(
        0.0,
        (sum, account) => sum + account.amount,
      );

      // Épargne (seulement principal, pas intérêts)
      final savingsAccounts = await SavingsAccountService()
          .getUserSavingsAccounts();
      total += savingsAccounts.fold<double>(
        0.0,
        (sum, account) => sum + account.principal,
      );

      // Investissement (seulement total_contribution)
      final investmentAccounts = await InvestmentService()
          .getUserInvestmentAccounts();
      total += investmentAccounts.fold<double>(
        0.0,
        (sum, account) => sum + account.cumulativeDeposits,
      );

      // Avantages (tout = déposé)
      final advantageAccounts = await AdvantageService()
          .getUserAdvantageAccounts();
      total += advantageAccounts.fold<double>(
        0.0,
        (sum, account) => sum + account.value,
      );

      return total;
    } catch (e) {
      rethrow;
    }
  }
}
