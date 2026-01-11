import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/database_tables.dart';
import '../models/patrimoine/patrimoine_category.dart';

class PatrimoineService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ✅ Singleton
  static final PatrimoineService _instance = PatrimoineService._internal();
  factory PatrimoineService() => _instance;
  PatrimoineService._internal();

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

      // 🔹 (Investissements & vouchers plus tard)

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
    // 🔜 À implémenter plus tard
    return false;
  }

  Future<bool> hasRestaurantVouchers() async {
    // 🔜 À implémenter plus tard
    return false;
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

      return response.map((item) => PatrimoineCategory(
        id: item['id'] as int,
        name: item['name'] as String,
        label: item['label'] as String? ?? '',
      )).toList();
    } catch (e) {
      rethrow;
    }
  }
}
