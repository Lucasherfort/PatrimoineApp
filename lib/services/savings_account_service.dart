import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/database_tables.dart';
import '../models/savings/user_savings_account_view.dart';

class SavingsAccountService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<UserSavingsAccountView>> getUserSavingsAccounts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from(DatabaseTables.userSavingsAccounts)
          .select('''
        id,
        principal,
        interest,
        savings_source (
          id,
          savings_category_id,
          bank_id,
          banks (id, name, icon),
          savings_category(name, interest_rate, ceiling)
        )
      ''')
          .eq('user_id', user.id);

      return response.map<UserSavingsAccountView>((item) {
        final source = item['savings_source'];
        final bank = source['banks'];
        final category = source['savings_category'];

        final iconPath = bank['icon'] as String?;
        String logoUrl = '';
        if (iconPath != null && iconPath.isNotEmpty) {
          logoUrl = _supabase.storage
              .from('banks-icons')
              .getPublicUrl(iconPath);
        }

        return UserSavingsAccountView(
          id: item['id'] as int,
          sourceName: category['name'] as String,
          bankName: bank['name'] as String,
          logoUrl: logoUrl,
          principal: (item['principal'] as num).toDouble(),
          interest: (item['interest'] as num).toDouble(),
          interestRate: (category['interest_rate'] as num?)
              ?.toDouble(), // 👈 Depuis savings_category
          ceiling: (category['ceiling'] as num?)
              ?.toDouble(), // 👈 Depuis savings_category
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// ----------------------------
  /// Met à jour un compte épargne (solde + intérêts)
  /// ----------------------------
  /// ----------------------------
  /// Met à jour un compte épargne (solde + intérêts)
  /// ----------------------------
  Future<bool> updateSavingsAccount({
    required int savingsAccountId,
    required double principal,
    required double interest,
  }) async {
    try {
      await _supabase
          .from(DatabaseTables.userSavingsAccounts)
          .update({
            'principal': principal,
            'interest': interest,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', savingsAccountId);

      // Si on arrive ici, la requête a été exécutée sans exception
      return true;
    } catch (e) {
      return false;
    }
  }

  /// ----------------------------
  /// Supprime un compte épargne
  /// ----------------------------
  Future<bool> deleteSavingsAccount(int accountId) async {
    try {
      final response = await _supabase
          .from(DatabaseTables.userSavingsAccounts)
          .delete()
          .eq('id', accountId);

      return response.error == null;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si un compte épargne peut être créé pour cette banque et catégorie
  /// Retourne true si le compte peut être créé, false s'il existe déjà
  Future<bool> canCreateSavingsAccount({
    required int bankId,
    required int savingsCategoryId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      // Vérifier si un savings_source existe déjà pour cette banque + catégorie
      final existingSource = await _supabase
          .from(DatabaseTables.savingsSource)
          .select('id')
          .eq('bank_id', bankId)
          .eq('savings_category_id', savingsCategoryId)
          .maybeSingle();

      // Si pas de source, on peut créer
      if (existingSource == null) {
        return true;
      }

      final sourceId = existingSource['id'] as int;

      // Vérifier si l'utilisateur a déjà un compte avec cette source
      final existingUserAccount = await _supabase
          .from(DatabaseTables.userSavingsAccounts)
          .select('id')
          .eq('user_id', user.id)
          .eq('savings_source_id', sourceId)
          .maybeSingle();

      // Si pas de compte utilisateur, on peut créer
      return existingUserAccount == null;
    } catch (e) {
      rethrow;
    }
  }

  /// ----------------------------
  /// Crée un compte épargne pour l'utilisateur connecté
  /// ----------------------------
  Future<int?> createSavingsAccount({
    required int bankId,
    required int categoryId,
    required int savingsCategoryId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // Vérifie si le savings_source existe déjà
      final existingSource = await _supabase
          .from(DatabaseTables.savingsSource)
          .select('id')
          .eq('bank_id', bankId)
          .eq('category_id', categoryId)
          .eq('savings_category_id', savingsCategoryId)
          .maybeSingle();

      final sourceId =
          existingSource?['id'] ??
          (await _supabase
              .from(DatabaseTables.savingsSource)
              .insert({
                'bank_id': bankId,
                'category_id': categoryId,
                'savings_category_id': savingsCategoryId,
              })
              .select('id')
              .single())['id'];

      // Crée le user_savings_account avec solde 0 et intérêts 0
      final account = await _supabase
          .from(DatabaseTables.userSavingsAccounts)
          .insert({
            'user_id': user.id,
            'savings_source_id': sourceId,
            'principal': 0,
            'interest': 0,
          })
          .select('id')
          .single();

      return account['id'] as int;
    } catch (e) {
      return null;
    }
  }
}
