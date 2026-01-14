import 'package:patrimoine/bdd/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/advantage/user_advantage_account_view.dart';

class AdvantageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Récupère tous les avantages de l’utilisateur
  Future<List<UserAdvantageAccountView>> getUserAdvantageAccounts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from(DatabaseTables.userAdvantageAccount)
          .select('''
          id,
          value,
          advantage_source (
            id,
            advantage_category_id,
            provider_id,
            advantage_provider (id, name),
            advantage_category(name)
          )
        ''')
          .eq('user_id', user.id);

      return response.map<UserAdvantageAccountView>((item) {
        final source = item['advantage_source'];
        final provider = source['advantage_provider'];
        final category = source['advantage_category'];

        return UserAdvantageAccountView(
          id: item['id'] as int,
          sourceName: category['name'] as String,
          providerName: provider['name'] as String,
          value: (item['value'] as num).toDouble()
        );
      }).toList();
    } catch (e)
    {
      return [];
    }
  }

  /// Met à jour la valeur d’un avantage
  Future<void> updateValue({required int accountId, required double value}) async {
    try {
      await _supabase
          .from('user_advantage_account')
          .update({'value': value})
          .eq('id', accountId);
    } catch (e) {
      rethrow;
    }
  }

  /// Supprime un avantage
  Future<void> deleteAccount(int accountId) async {
    try {
      await _supabase
          .from('user_advantage_account')
          .delete()
          .eq('id', accountId);
    } catch (e) {
      rethrow;
    }
  }
}