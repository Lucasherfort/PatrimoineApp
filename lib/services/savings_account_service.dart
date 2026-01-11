import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/savings/user_savings_account_view.dart';

class SavingsAccountService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<UserSavingsAccountView>> getUserSavingsAccounts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('user_savings_account')
          .select('''
          id,
          principal,
          interest,
          savings_source (
            id,
            savings_category_id,
            bank_id,
            banks (id, name),
            savings_category(name)
          )
        ''')
          .eq('user_id', user.id);

      if (response is! List) return [];

      return response.map<UserSavingsAccountView>((item) {
        final source = item['savings_source'];
        final bank = source['banks'];
        final category = source['savings_category'];

        return UserSavingsAccountView(
          id: item['id'] as int,
          sourceName: category['name'] as String,
          bankName: bank['name'] as String,
          principal: (item['principal'] as num).toDouble(),
          interest: (item['interest'] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      print('Erreur getUserSavingsAccounts: $e');
      return [];
    }
  }

  /// ----------------------------
  /// Met à jour un compte épargne (solde + intérêts)
  /// ----------------------------
  Future<bool> updateSavingsAccount({
    required int accountId,
    required double balance,
    required double interestAccrued,
  }) async {
    try {
      final response = await _supabase
          .from('user_savings_account')
          .update({
        'principal': balance,
        'interest': interestAccrued,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', accountId);

      return response.error == null;
    } catch (e) {
      print('Erreur updateSavingsAccount: $e');
      return false;
    }
  }

  /// ----------------------------
  /// Supprime un compte épargne
  /// ----------------------------
  Future<bool> deleteSavingsAccount(int accountId) async {
    try {
      final response = await _supabase
          .from('user_savings_account')
          .delete()
          .eq('id', accountId);

      return response.error == null;
    } catch (e) {
      print('Erreur deleteSavingsAccount: $e');
      return false;
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
          .from('savings_source')
          .select('id')
          .eq('bank_id', bankId)
          .eq('category_id', categoryId)
          .eq('savings_category_id', savingsCategoryId)
          .maybeSingle();

      final sourceId = existingSource?['id'] ??
          (await _supabase
              .from('savings_source')
              .insert({
            'bank_id': bankId,
            'category_id': categoryId,
            'savings_category_id': savingsCategoryId,
          })
              .select('id')
              .single())['id'];

      // Crée le user_savings_account avec solde 0 et intérêts 0
      final account = await _supabase
          .from('user_savings_account')
          .insert({
        'user_id': user.id,
        'savings_source_id': sourceId,
        'principal': 0,
        'interest': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .select('id')
          .single();

      return account['id'] as int;
    } catch (e) {
      print('Erreur createSavingsAccount: $e');
      return null;
    }
  }
}