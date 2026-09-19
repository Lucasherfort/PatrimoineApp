import 'package:flutter/cupertino.dart';
import 'package:patrimoine360/bdd/banks_table.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/savings_category_table.dart';
import '../bdd/savings_source_table.dart';
import '../bdd/storage_buckets.dart';
import '../bdd/user_savings_account_table.dart';
import '../models/savings/user_savings_account_view.dart';

class SavingsAccountService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Sélects ──────────────────────────────────────────────────────────────

  static const _selectAccounts =
      '''
    ${UserSavingsAccountTable.id},
    ${UserSavingsAccountTable.principal},
    ${UserSavingsAccountTable.interest},
    ${SavingsSourceTable.tableName} (
      ${SavingsSourceTable.id},
      ${SavingsSourceTable.savingsCategoryId},
      ${SavingsSourceTable.bankId},
      ${BanksTable.tableName} (
        ${BanksTable.id},
        ${BanksTable.name},
        ${BanksTable.icon}
      ),
      ${SavingsCategoryTable.tableName} (
        ${SavingsCategoryTable.name},
        ${SavingsCategoryTable.interestRate},
        ${SavingsCategoryTable.ceiling}
      )
    )
  ''';

  // ─── Lecture ──────────────────────────────────────────────────────────────

  Future<List<UserSavingsAccountView>> getUserSavingsAccounts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from(UserSavingsAccountTable.tableName)
          .select(_selectAccounts)
          .eq(UserSavingsAccountTable.userId, user.id);

      return response.map<UserSavingsAccountView>(_mapToView).toList();
    } catch (e, stack) {
      debugPrint('ERREUR getUserSavingsAccounts: $e');
      debugPrint('STACK: $stack');
      return [];
    }
  }

  // ─── Écriture ─────────────────────────────────────────────────────────────

  Future<bool> updateSavingsAccount({
    required int savingsAccountId,
    required double principal,
    required double interest,
    required bool automaticInterestCalculation,
  }) async {
    try {
      await _supabase
          .from(UserSavingsAccountTable.tableName)
          .update({
            UserSavingsAccountTable.principal: principal,
            UserSavingsAccountTable.interest: interest,
            UserSavingsAccountTable.automaticInterestCalculation:
                automaticInterestCalculation,
            UserSavingsAccountTable.updatedAt: DateTime.now().toIso8601String(),
          })
          .eq(UserSavingsAccountTable.id, savingsAccountId);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSavingsAccount(int accountId) async {
    try {
      await _supabase
          .from(UserSavingsAccountTable.tableName)
          .delete()
          .eq(UserSavingsAccountTable.id, accountId);

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
        .from(SavingsSourceTable.tableName)
        .select(SavingsSourceTable.id)
        .eq(SavingsSourceTable.bankId, bankId)
        .eq(SavingsSourceTable.savingsCategoryId, savingsCategoryId)
        .maybeSingle();

    if (existingSource == null) return true;

    final sourceId = existingSource[SavingsSourceTable.id] as int;

    final existingUserAccount = await _supabase
        .from(UserSavingsAccountTable.tableName)
        .select(UserSavingsAccountTable.id)
        .eq(UserSavingsAccountTable.userId, user.id)
        .eq(UserSavingsAccountTable.savingsSourceId, sourceId)
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
          .from(SavingsSourceTable.tableName)
          .select(SavingsSourceTable.id)
          .eq(SavingsSourceTable.bankId, bankId)
          .eq(SavingsSourceTable.categoryId, categoryId)
          .eq(SavingsSourceTable.savingsCategoryId, savingsCategoryId)
          .maybeSingle();

      final sourceId =
          existingSource?[SavingsSourceTable.id] ??
          (await _supabase
              .from(SavingsSourceTable.tableName)
              .insert({
                SavingsSourceTable.bankId: bankId,
                SavingsSourceTable.categoryId: categoryId,
                SavingsSourceTable.savingsCategoryId: savingsCategoryId,
              })
              .select(SavingsSourceTable.id)
              .single())[SavingsSourceTable.id];

      final account = await _supabase
          .from(UserSavingsAccountTable.tableName)
          .insert({
            UserSavingsAccountTable.userId: user.id,
            UserSavingsAccountTable.savingsSourceId: sourceId,
            UserSavingsAccountTable.principal: 0,
            UserSavingsAccountTable.interest: 0,
          })
          .select(UserSavingsAccountTable.id)
          .single();

      return account[UserSavingsAccountTable.id] as int;
    } catch (e) {
      return null;
    }
  }

  // ─── Helpers privés ───────────────────────────────────────────────────────

  UserSavingsAccountView _mapToView(Map<String, dynamic> item) {
    try {
      dynamic sourceRaw = item[SavingsSourceTable.tableName];
      final source = sourceRaw is List
          ? sourceRaw.first
          : sourceRaw as Map<String, dynamic>?;

      if (source == null) {
        throw Exception(
          "Relation 'savings_source' manquante pour le compte ID: ${item[UserSavingsAccountTable.id]}",
        );
      }

      dynamic bankRaw = source[BanksTable.tableName];
      final bank = bankRaw is List
          ? bankRaw.first
          : bankRaw as Map<String, dynamic>?;

      if (bank == null) {
        throw Exception(
          "Relation 'banks' manquante pour le compte ID: ${item[UserSavingsAccountTable.id]}",
        );
      }

      dynamic categoryRaw = source[SavingsCategoryTable.tableName];
      final category = categoryRaw is List
          ? categoryRaw.first
          : categoryRaw as Map<String, dynamic>?;

      if (category == null) {
        throw Exception(
          "Relation 'savings_category' manquante pour le compte ID: ${item[UserSavingsAccountTable.id]}",
        );
      }

      return UserSavingsAccountView(
        id: item[UserSavingsAccountTable.id] as int,
        sourceName: category[SavingsCategoryTable.name] as String,
        bankName: bank[BanksTable.name] as String,
        logoUrl: _resolveLogoUrl(bank[BanksTable.icon] as String?),
        principal:
            (item[UserSavingsAccountTable.principal] as num?)?.toDouble() ??
            0.0,
        interest:
            (item[UserSavingsAccountTable.interest] as num?)?.toDouble() ?? 0.0,
        interestRate: (category[SavingsCategoryTable.interestRate] as num?)
            ?.toDouble(),
        ceiling: (category[SavingsCategoryTable.ceiling] as num?)?.toDouble(),
      );
    } catch (e) {
      debugPrint('ERREUR _mapToView Savings: $e');
      debugPrint('ITEM DATA: $item');
      rethrow;
    }
  }

  String _resolveLogoUrl(String? iconPath) {
    if (iconPath == null || iconPath.isEmpty) return '';
    return _supabase.storage
        .from(StorageBucketsTable.banksIcons)
        .getPublicUrl(iconPath);
  }

  /// Récupère la valeur totale de l'épargne (Principal + Intérêts)
  Future<double> getTotalSavingsValue() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0.0;

    final response = await _supabase
        .from(UserSavingsAccountTable.tableName)
        .select(
          '${UserSavingsAccountTable.principal}, ${UserSavingsAccountTable.interest}',
        )
        .eq(UserSavingsAccountTable.userId, user.id);

    return response.fold<double>(
      0.0,
      (sum, row) =>
          sum +
          ((row[UserSavingsAccountTable.principal] as num?)?.toDouble() ?? 0) +
          ((row[UserSavingsAccountTable.interest] as num?)?.toDouble() ?? 0),
    );
  }

  /// Récupère la valeur totale nette estimée de l'épargne (fiscalité déduite si applicable)
  Future<double> getTotalSavingsValueNet() async {
    return getTotalSavingsValue();
  }

  /// Récupère uniquement le capital déposé (Principal) de l'épargne.
  Future<double> getTotalSavingsPrincipal() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0.0;

    final response = await _supabase
        .from(UserSavingsAccountTable.tableName)
        .select(UserSavingsAccountTable.principal)
        .eq(UserSavingsAccountTable.userId, user.id);

    return response.fold<double>(
      0.0,
      (sum, row) =>
          sum +
          ((row[UserSavingsAccountTable.principal] as num?)?.toDouble() ?? 0),
    );
  }
}
