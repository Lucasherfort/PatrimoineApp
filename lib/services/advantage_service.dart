import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/AdvantageCategory.dart';
import '../bdd/AdvantageProvider.dart';
import '../bdd/AdvantageSource.dart';
import '../bdd/UserAdvantageAccount.dart';
import '../bdd/storage_buckets.dart';
import '../models/advantage/user_advantage_account_view.dart';

class AdvantageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const _selectQuery = '''
    ${UserAdvantageAccount.id},
    ${UserAdvantageAccount.value},
    ${AdvantageSource.table} (
      ${UserAdvantageAccount.id},
      ${AdvantageSource.advantageCategoryId},
      ${AdvantageSource.providerId},
      ${AdvantageProvider.table} (
        ${AdvantageProvider.id},
        ${AdvantageProvider.name},
        ${AdvantageProvider.icon}
      ),
      ${AdvantageCategory.table} (
        ${AdvantageCategory.name}
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
          .from(UserAdvantageAccount.table)
          .select(_selectQuery)
          .eq(UserAdvantageAccount.userId, user.id);

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
    final source = item[AdvantageSource.table] as Map<String, dynamic>;
    final provider = source[AdvantageProvider.table] as Map<String, dynamic>;
    final category = source[AdvantageCategory.table] as Map<String, dynamic>;

    final iconPath = provider[AdvantageProvider.icon] as String?;
    final logoUrl = _resolveLogoUrl(iconPath);

    return UserAdvantageAccountView(
      id: item[UserAdvantageAccount.id] as int,
      sourceName: category[AdvantageCategory.name] as String,
      providerName: provider[AdvantageProvider.name] as String,
      logoUrl: logoUrl,
      value: (item[UserAdvantageAccount.value] as num).toDouble(),
    );
  }

  /// Construit l'URL publique d'un logo à partir de son chemin dans le bucket.
  ///
  /// Retourne une chaîne vide si le chemin est null ou vide.
  String _resolveLogoUrl(String? iconPath) {
    if (iconPath == null || iconPath.isEmpty) return '';
    return _supabase.storage
        .from(StorageBuckets.banksIcons)
        .getPublicUrl(iconPath);
  }

  /// Met à jour la valeur d'un compte avantage.
  Future<void> updateValue({
    required int accountId,
    required double value,
  }) async {
    await _supabase
        .from(UserAdvantageAccount.table)
        .update({UserAdvantageAccount.value: value})
        .eq(UserAdvantageAccount.id, accountId);
  }

  /// Supprime un compte avantage.
  Future<void> deleteAccount(int accountId) async {
    await _supabase
        .from(UserAdvantageAccount.table)
        .delete()
        .eq(UserAdvantageAccount.id, accountId);
  }
}