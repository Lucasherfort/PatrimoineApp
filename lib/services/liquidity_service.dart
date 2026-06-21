import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/banks_table.dart';
import '../bdd/liquidity_category_table.dart';
import '../bdd/liquidity_source_table.dart';
import '../bdd/storage_buckets.dart';
import '../bdd/user_liquidity_account_table.dart';
import '../models/liquidity/user_liquidity_account_view.dart';
import 'auth_service.dart';

class LiquidityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const _selectAccounts =
      '''
    ${UserLiquidityAccountTable.id},
    ${UserLiquidityAccountTable.amount},
    ${LiquiditySourceTable.tableName} (
      ${LiquiditySourceTable.id},
      ${LiquiditySourceTable.liquidityCategoryId},
      ${LiquiditySourceTable.bankId},
      ${BanksTable.tableName} (
        ${BanksTable.id},
        ${BanksTable.name},
        ${BanksTable.icon}
      ),
      ${LiquidityCategoryTable.tableName} (
        ${LiquidityCategoryTable.name}
      )
    )
  ''';

  // ─── Lecture ──────────────────────────────────────────────────────────────

  Future<List<UserLiquidityAccountView>> getUserLiquidityAccounts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final response = await _supabase
        .from(UserLiquidityAccountTable.tableName)
        .select(_selectAccounts)
        .eq(UserLiquidityAccountTable.userId, user.id)
        .order(UserLiquidityAccountTable.id);

    return response.map<UserLiquidityAccountView>(_mapToView).toList();
  }

  // ─── Écriture ─────────────────────────────────────────────────────────────

  Future<void> createLiquidityAccount({required int liquiditySourceId}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final now = DateTime.now().toIso8601String();

    await _supabase.from(UserLiquidityAccountTable.tableName).insert({
      UserLiquidityAccountTable.userId: user.id,
      UserLiquidityAccountTable.liquiditySourceId: liquiditySourceId,
      UserLiquidityAccountTable.amount: 0,
      UserLiquidityAccountTable.createdAt: now,
      UserLiquidityAccountTable.updatedAt: now,
    });
  }

  Future<void> updateAmount({
    required int accountId,
    required double amount,
  }) async {
    await _supabase
        .from(UserLiquidityAccountTable.tableName)
        .update({
          UserLiquidityAccountTable.amount: amount,
          UserLiquidityAccountTable.updatedAt: DateTime.now().toIso8601String(),
        })
        .eq(UserLiquidityAccountTable.id, accountId);
  }

  Future<void> deleteAccount(int accountId) async {
    await _supabase
        .from(UserLiquidityAccountTable.tableName)
        .delete()
        .eq(UserLiquidityAccountTable.id, accountId);
  }

  // ─── Helpers privés ───────────────────────────────────────────────────────

  UserLiquidityAccountView _mapToView(Map<String, dynamic> item) {
    final source = item[LiquiditySourceTable.tableName] as Map<String, dynamic>;
    final bank = source[BanksTable.tableName] as Map<String, dynamic>;
    final category =
        source[LiquidityCategoryTable.tableName] as Map<String, dynamic>;

    return UserLiquidityAccountView(
      id: item[UserLiquidityAccountTable.id] as int,
      amount: (item[UserLiquidityAccountTable.amount] as num).toDouble(),
      sourceName: category[LiquidityCategoryTable.name] as String,
      bankName: bank[BanksTable.name] as String,
      logoUrl: _resolveLogoUrl(bank[BanksTable.icon] as String?),
    );
  }

  String _resolveLogoUrl(String? iconPath) {
    if (iconPath == null || iconPath.isEmpty) return '';
    return _supabase.storage
        .from(StorageBucketsTable.banksIcons)
        .getPublicUrl(iconPath);
  }

  /////////////////////////////////////////////////////////////////////
  Future<double> getTotalLiquidityValue() async {
    final userId = AuthService().requireUserId();

    final liquidity = await _supabase
        .from(UserLiquidityAccountTable.tableName)
        .select(UserLiquidityAccountTable.amount)
        .eq(UserLiquidityAccountTable.userId, userId);

    // Somme des montants
    return liquidity.fold<double>(
      0.0,
          (sum, row) =>
      sum +
          ((row[UserLiquidityAccountTable.amount] as num?)?.toDouble() ?? 0),
    );
  }
}
