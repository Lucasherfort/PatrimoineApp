import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/database_columns.dart';
import '../bdd/database_tables.dart';
import '../bdd/storage_buckets.dart';
import '../models/liquidity/user_liquidity_account_view.dart';

class LiquidityAccountService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const _selectAccounts =
      '''
    ${LiquidityAccountColumns.id},
    ${LiquidityAccountColumns.amount},
    ${DatabaseTables.liquiditySource} (
      ${LiquiditySourceColumns.id},
      ${LiquiditySourceColumns.liquidityCategoryId},
      ${LiquiditySourceColumns.bankId},
      ${DatabaseTables.banks} (
        ${BankColumns.id},
        ${BankColumns.name},
        ${BankColumns.icon}
      ),
      ${DatabaseTables.liquidityCategory} (
        ${LiquidityCategoryColumns.name}
      )
    )
  ''';

  // ─── Lecture ──────────────────────────────────────────────────────────────

  Future<List<UserLiquidityAccountView>> getUserLiquidityAccounts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final response = await _supabase
        .from(DatabaseTables.userLiquidityAccounts)
        .select(_selectAccounts)
        .eq(LiquidityAccountColumns.userId, user.id)
        .order(LiquidityAccountColumns.id);

    return response.map<UserLiquidityAccountView>(_mapToView).toList();
  }

  // ─── Écriture ─────────────────────────────────────────────────────────────

  Future<void> createLiquidityAccount({required int liquiditySourceId}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final now = DateTime.now().toIso8601String();

    await _supabase.from(DatabaseTables.userLiquidityAccounts).insert({
      LiquidityAccountColumns.userId: user.id,
      LiquidityAccountColumns.liquiditySourceId: liquiditySourceId,
      LiquidityAccountColumns.amount: 0,
      LiquidityAccountColumns.createdAt: now,
      LiquidityAccountColumns.updatedAt: now,
    });
  }

  Future<void> updateAmount({
    required int accountId,
    required double amount,
  }) async {
    await _supabase
        .from(DatabaseTables.userLiquidityAccounts)
        .update({
          LiquidityAccountColumns.amount: amount,
          LiquidityAccountColumns.updatedAt: DateTime.now().toIso8601String(),
        })
        .eq(LiquidityAccountColumns.id, accountId);
  }

  Future<void> deleteAccount(int accountId) async {
    await _supabase
        .from(DatabaseTables.userLiquidityAccounts)
        .delete()
        .eq(LiquidityAccountColumns.id, accountId);
  }

  // ─── Helpers privés ───────────────────────────────────────────────────────

  UserLiquidityAccountView _mapToView(Map<String, dynamic> item) {
    final source = item[DatabaseTables.liquiditySource] as Map<String, dynamic>;
    final bank = source[DatabaseTables.banks] as Map<String, dynamic>;
    final category =
        source[DatabaseTables.liquidityCategory] as Map<String, dynamic>;

    return UserLiquidityAccountView(
      id: item[LiquidityAccountColumns.id] as int,
      amount: (item[LiquidityAccountColumns.amount] as num).toDouble(),
      sourceName: category[LiquidityCategoryColumns.name] as String,
      bankName: bank[BankColumns.name] as String,
      logoUrl: _resolveLogoUrl(bank[BankColumns.icon] as String?),
    );
  }

  String _resolveLogoUrl(String? iconPath) {
    if (iconPath == null || iconPath.isEmpty) return '';
    return _supabase.storage
        .from(StorageBuckets.banksIcons)
        .getPublicUrl(iconPath);
  }
}
