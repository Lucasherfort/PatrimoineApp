import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/database_columns.dart';
import '../bdd/database_tables.dart';
import '../bdd/storage_buckets.dart';
import '../models/savings/user_savings_account_view.dart';

class SavingsAccountService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Sélects ──────────────────────────────────────────────────────────────

  static const _selectAccounts = '''
    ${UserSavingsAccountColumns.id},
    ${UserSavingsAccountColumns.principal},
    ${UserSavingsAccountColumns.interest},
    ${DatabaseTables.savingsSource} (
      ${SavingsSourceColumns.id},
      ${SavingsSourceColumns.savingsCategoryId},
      ${SavingsSourceColumns.bankId},
      ${DatabaseTables.banks} (
        ${BankColumns.id},
        ${BankColumns.name},
        ${BankColumns.icon}
      ),
      ${DatabaseTables.savingsCategory} (
        ${SavingsCategoryColumns.name},
        ${SavingsCategoryColumns.interestRate},
        ${SavingsCategoryColumns.ceiling}
      )
    )
  ''';

  // ─── Lecture ──────────────────────────────────────────────────────────────

  Future<List<UserSavingsAccountView>> getUserSavingsAccounts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from(DatabaseTables.userSavingsAccounts)
          .select(_selectAccounts)
          .eq(UserSavingsAccountColumns.userId, user.id);

      return response.map<UserSavingsAccountView>(_mapToView).toList();
    } catch (e) {
      return [];
    }
  }

  // ─── Écriture ─────────────────────────────────────────────────────────────

  Future<bool> updateSavingsAccount({
    required int savingsAccountId,
    required double principal,
    required double interest,
  }) async {
    try {
      await _supabase
          .from(DatabaseTables.userSavingsAccounts)
          .update({
        UserSavingsAccountColumns.principal: principal,
        UserSavingsAccountColumns.interest: interest,
        UserSavingsAccountColumns.updatedAt: DateTime.now().toIso8601String(),
      })
          .eq(UserSavingsAccountColumns.id, savingsAccountId);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSavingsAccount(int accountId) async {
    try {
      await _supabase
          .from(DatabaseTables.userSavingsAccounts)
          .delete()
          .eq(UserSavingsAccountColumns.id, accountId);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> canCreateSavingsAccount({
    required int bankId,
    required int savingsCategoryId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final existingSource = await _supabase
        .from(DatabaseTables.savingsSource)
        .select(SavingsSourceColumns.id)
        .eq(SavingsSourceColumns.bankId, bankId)
        .eq(SavingsSourceColumns.savingsCategoryId, savingsCategoryId)
        .maybeSingle();

    if (existingSource == null) return true;

    final sourceId = existingSource[SavingsSourceColumns.id] as int;

    final existingUserAccount = await _supabase
        .from(DatabaseTables.userSavingsAccounts)
        .select(UserSavingsAccountColumns.id)
        .eq(UserSavingsAccountColumns.userId, user.id)
        .eq(UserSavingsAccountColumns.savingsSourceId, sourceId)
        .maybeSingle();

    return existingUserAccount == null;
  }

  Future<int?> createSavingsAccount({
    required int bankId,
    required int categoryId,
    required int savingsCategoryId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final existingSource = await _supabase
          .from(DatabaseTables.savingsSource)
          .select(SavingsSourceColumns.id)
          .eq(SavingsSourceColumns.bankId, bankId)
          .eq(SavingsSourceColumns.categoryId, categoryId)
          .eq(SavingsSourceColumns.savingsCategoryId, savingsCategoryId)
          .maybeSingle();

      final sourceId =
          existingSource?[SavingsSourceColumns.id] ??
              (await _supabase
                  .from(DatabaseTables.savingsSource)
                  .insert({
                SavingsSourceColumns.bankId: bankId,
                SavingsSourceColumns.categoryId: categoryId,
                SavingsSourceColumns.savingsCategoryId: savingsCategoryId,
              })
                  .select(SavingsSourceColumns.id)
                  .single())[SavingsSourceColumns.id];

      final account = await _supabase
          .from(DatabaseTables.userSavingsAccounts)
          .insert({
        UserSavingsAccountColumns.userId: user.id,
        UserSavingsAccountColumns.savingsSourceId: sourceId,
        UserSavingsAccountColumns.principal: 0,
        UserSavingsAccountColumns.interest: 0,
      })
          .select(UserSavingsAccountColumns.id)
          .single();

      return account[UserSavingsAccountColumns.id] as int;
    } catch (e) {
      return null;
    }
  }

  // ─── Helpers privés ───────────────────────────────────────────────────────

  UserSavingsAccountView _mapToView(Map<String, dynamic> item) {
    final source = item[DatabaseTables.savingsSource] as Map<String, dynamic>;
    final bank = source[DatabaseTables.banks] as Map<String, dynamic>;
    final category = source[DatabaseTables.savingsCategory] as Map<String, dynamic>;

    return UserSavingsAccountView(
      id: item[UserSavingsAccountColumns.id] as int,
      sourceName: category[SavingsCategoryColumns.name] as String,
      bankName: bank[BankColumns.name] as String,
      logoUrl: _resolveLogoUrl(bank[BankColumns.icon] as String?),
      principal: (item[UserSavingsAccountColumns.principal] as num).toDouble(),
      interest: (item[UserSavingsAccountColumns.interest] as num).toDouble(),
      interestRate: (category[SavingsCategoryColumns.interestRate] as num?)?.toDouble(),
      ceiling: (category[SavingsCategoryColumns.ceiling] as num?)?.toDouble(),
    );
  }

  String _resolveLogoUrl(String? iconPath) {
    if (iconPath == null || iconPath.isEmpty) return '';
    return _supabase.storage.from(StorageBuckets.banksIcons).getPublicUrl(iconPath);
  }
}