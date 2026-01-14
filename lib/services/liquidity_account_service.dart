import 'package:patrimoine/bdd/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/liquidity/user_liquidity_account_view.dart';

class LiquidityAccountService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─────────────────────────────────────────────
  // 📥 LISTE DES COMPTES LIQUIDITÉS
  // ─────────────────────────────────────────────
  Future<List<UserLiquidityAccountView>> getUserLiquidityAccounts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final response = await _supabase
        .from(DatabaseTables.userLiquidityAccounts)
        .select('''
          id,
          amount,
          liquidity_source (
            name,
            banks ( name )
          )
        ''')
        .eq('user_id', user.id)
        .order('id');

    return response.map<UserLiquidityAccountView>((item) {
      return UserLiquidityAccountView(
        id: item['id'] as int,
        amount: (item['amount'] as num).toDouble(),
        sourceName: item['liquidity_source']['name'] as String,
        bankName: item['liquidity_source']['banks']['name'] as String,
      );
    }).toList();
  }

  // ─────────────────────────────────────────────
  // ➕ CRÉATION D’UN COMPTE
  // ─────────────────────────────────────────────
  Future<void> createLiquidityAccount({
    required int liquiditySourceId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    await _supabase.from(DatabaseTables.userLiquidityAccounts).insert({
      'user_id': user.id,
      'liquidity_source_id': liquiditySourceId,
      'amount': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ─────────────────────────────────────────────
  // ✏️ MISE À JOUR DU MONTANT
  // ─────────────────────────────────────────────
  Future<void> updateAmount({
    required int accountId,
    required double amount,
  }) async {
    await _supabase
        .from(DatabaseTables.userLiquidityAccounts)
        .update({
      'amount': amount,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', accountId);
  }

  // ─────────────────────────────────────────────
  // 🗑️ SUPPRESSION
  // ─────────────────────────────────────────────
  Future<void> deleteAccount(int accountId) async {
    await _supabase
        .from(DatabaseTables.userLiquidityAccounts)
        .delete()
        .eq('id', accountId);
  }
}