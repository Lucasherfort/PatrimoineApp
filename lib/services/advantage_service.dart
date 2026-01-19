
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/database_tables.dart';
import '../models/advantage/user_advantage_account_view.dart';

class AdvantageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Récupère tous les comptes avantages de l’utilisateur
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
          advantage_provider (id, name, icon),
          advantage_category(name)
        )
      ''')
          .eq('user_id', user.id);

      return response.map<UserAdvantageAccountView>((item) {
        final source = item['advantage_source'];
        final provider = source['advantage_provider'];
        final category = source['advantage_category'];

        // Construire l'URL publique complète pour l'icône
        final iconPath = provider['icon'] as String?;
        String logoUrl = '';
        if (iconPath != null && iconPath.isNotEmpty) {
          logoUrl = _supabase.storage
              .from('banks-icons') // 👈 Même bucket que les banques
              .getPublicUrl(iconPath);
        }

        return UserAdvantageAccountView(
          id: item['id'] as int,
          sourceName: category['name'] as String,
          providerName: provider['name'] as String,
          logoUrl: logoUrl, // 👈 Ajout du logo
          value: (item['value'] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Met à jour la valeur d’un compte advantage
  Future<void> updateValue({required int accountId, required double value}) async {
    try {
      await _supabase
          .from(DatabaseTables.userAdvantageAccount)
          .update({'value': value})
          .eq('id', accountId);
    } catch (e) {
      rethrow;
    }
  }

  /// Supprime un compte advantage
  Future<void> deleteAccount(int accountId) async {
    try {
      await _supabase
          .from(DatabaseTables.userAdvantageAccount)
          .delete()
          .eq('id', accountId);
    } catch (e) {
      rethrow;
    }
  }
}