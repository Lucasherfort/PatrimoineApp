import 'package:patrimoine/bdd/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/investments/UserInvestmentAccountView.dart';

class InvestmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  InvestmentService();

  /// Récupère tous les comptes investissements de l'utilisateur
  Future<List<UserInvestmentAccountView>> getInvestmentAccountsForUserWithPrices() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final response = await _supabase
          .from(DatabaseTables.userInvestmentAccount)
          .select('''
      id,
      amount,
      investment_source (
        id,
        bank_id,
        banks (id, name),
        investment_category (name)
      )
    ''')
          .eq('user_id', user.id);

      return response.map<UserInvestmentAccountView>((item) {
        final source = item['investment_source'];
        final bank = source['banks'];
        final category = source['investment_category'];

        return UserInvestmentAccountView(
          id: item['id'] as int,
          sourceName: category['name'] as String,
          bankName: bank['name'] as String,
          totalValue: (item['amount'] as num).toDouble(),
        );
      }).toList();
    } catch (e)
    {
      return [];
    }
  }

  /// Supprime un compte investissement
  Future<void> deleteUserInvestmentAccount(int accountId) async {
    try {
      await _supabase
          .from(DatabaseTables.userInvestmentAccount)
          .delete()
          .eq('id', accountId);
      // ⚠️ les positions liées seront supprimées automatiquement si cascade est activé sur la BDD
    } catch (e) {
      rethrow;
    }
  }

  /// Met à jour un compte investissement
  Future<void> updateInvestmentAccount({
    required int accountId,
    required double totalValue,
    required double performance,
  }) async {
    try {
      await _supabase.from(DatabaseTables.userInvestmentAccount).update({
        'total_value': totalValue,
        'performance': performance,
      }).eq('id', accountId);
    } catch (e) {
      rethrow;
    }
  }

  /// Crée un compte investissement
  Future<void> createUserInvestmentAccount({
    required int userId,
    required int investmentSourceId,
    required double initialValue,
  }) async {
    try {
      await _supabase.from(DatabaseTables.userInvestmentAccount).insert({
        'user_id': userId,
        'investment_source_id': investmentSourceId,
        'total_value': initialValue,
        'performance': 0.0,
      });
    } catch (e) {
      rethrow;
    }
  }
}