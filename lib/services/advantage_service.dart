import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/advantage_category_table.dart';
import '../bdd/advantage_provider_table.dart';
import '../bdd/advantage_source_table.dart';
import '../bdd/user_advantage_account_table.dart';
import '../bdd/storage_buckets.dart';
import '../models/advantage/user_advantage_account_view.dart';

class AdvantageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const _selectQuery =
      '''
    ${UserAdvantageAccountTable.id},
    ${UserAdvantageAccountTable.value},
    ${AdvantageSourceTable.tableName} (
      ${UserAdvantageAccountTable.id},
      ${AdvantageSourceTable.advantageCategoryId},
      ${AdvantageSourceTable.providerId},
      ${AdvantageProviderTable.tableName} (
        ${AdvantageProviderTable.id},
        ${AdvantageProviderTable.name},
        ${AdvantageProviderTable.icon}
      ),
      ${AdvantageCategoryTable.tableName} (
        ${AdvantageCategoryTable.name}
      )
    )
  ''';

  /// Récupère la liste des comptes avantages de l'utilisateur connecté.
  ///
  /// Retourne une liste vide si l'utilisateur n'est pas connecté
  /// ou si une erreur survient lors de la requête.
  Future<List<UserAdvantageAccountView>> getUserAdvantageAccounts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from(UserAdvantageAccountTable.tableName)
          .select(_selectQuery)
          .eq(UserAdvantageAccountTable.userId, user.id);

      return response.map<UserAdvantageAccountView>(_mapToView).toList();
    } catch (e) {
      return [];
    }
  }

  /// Convertit une ligne brute Supabase en [UserAdvantageAccountView].
  ///
  /// Extrait les relations imbriquées source, fournisseur et catégorie,
  /// puis résout l'URL publique du logo.
  UserAdvantageAccountView _mapToView(Map<String, dynamic> item) {
    final source = item[AdvantageSourceTable.tableName] as Map<String, dynamic>;
    final provider =
        source[AdvantageProviderTable.tableName] as Map<String, dynamic>;
    final category =
        source[AdvantageCategoryTable.tableName] as Map<String, dynamic>;

    final iconPath = provider[AdvantageProviderTable.icon] as String?;
    final logoUrl = _resolveLogoUrl(iconPath);

    return UserAdvantageAccountView(
      id: item[UserAdvantageAccountTable.id] as int,
      sourceName: category[AdvantageCategoryTable.name] as String,
      providerName: provider[AdvantageProviderTable.name] as String,
      logoUrl: logoUrl,
      value: (item[UserAdvantageAccountTable.value] as num).toDouble(),
    );
  }

  /// Construit l'URL publique d'un logo à partir de son chemin dans le bucket.
  ///
  /// Retourne une chaîne vide si le chemin est null ou vide.
  String _resolveLogoUrl(String? iconPath) {
    if (iconPath == null || iconPath.isEmpty) return '';
    return _supabase.storage
        .from(StorageBucketsTable.banksIcons)
        .getPublicUrl(iconPath);
  }

  /// Met à jour la valeur d'un compte avantage.
  Future<void> updateValue({
    required int accountId,
    required double value,
  }) async {
    await _supabase
        .from(UserAdvantageAccountTable.tableName)
        .update({UserAdvantageAccountTable.value: value})
        .eq(UserAdvantageAccountTable.id, accountId);
  }

  /// Supprime un compte avantage.
  Future<void> deleteAccount(int accountId) async {
    await _supabase
        .from(UserAdvantageAccountTable.tableName)
        .delete()
        .eq(UserAdvantageAccountTable.id, accountId);
  }

  /// Récupère la valeur totale des avantages salariés.
  Future<double> getTotalAdvantageValue() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0.0;

    final response = await _supabase
        .from(UserAdvantageAccountTable.tableName)
        .select(UserAdvantageAccountTable.value)
        .eq(UserAdvantageAccountTable.userId, user.id);

    return response.fold<double>(
      0.0,
      (sum, row) =>
          sum +
          ((row[UserAdvantageAccountTable.value] as num?)?.toDouble() ?? 0),
    );
  }
}
