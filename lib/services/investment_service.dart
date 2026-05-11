import 'package:supabase_flutter/supabase_flutter.dart';

import '../bdd/banks_table.dart';
import '../bdd/investment_category_table.dart';
import '../bdd/investment_source_table.dart';
import '../bdd/positions_table.dart';
import '../bdd/storage_buckets.dart';
import '../bdd/user_investment_account_table.dart';
import '../bdd/user_investment_position_table.dart';
import '../models/investment_position.dart';
import '../models/investments/user_investment_account_view.dart';
import '../models/user_investment_account.dart';

class InvestmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static final InvestmentService _instance = InvestmentService._internal();
  factory InvestmentService() => _instance;
  InvestmentService._internal();

  // ─── Requêtes SELECT ────────────────────────────────────────────────────────

  static const _selectAccountsWithPrices =
      '''
    ${UserInvestmentAccountTable.id},
    ${UserInvestmentAccountTable.totalContribution},
    ${UserInvestmentAccountTable.cashBalance},
    ${UserInvestmentAccountTable.amount},
    ${InvestmentSourceTable.tableName} (
      ${InvestmentSourceTable.id},
      ${InvestmentSourceTable.bankId},
      ${BanksTable.tableName} (
        ${BanksTable.id},
        ${BanksTable.name},
        ${BanksTable.icon}
      ),
      ${InvestmentCategoryTable.tableName} (
        ${InvestmentCategoryTable.name}
      )
    )
  ''';

  static const _selectSourceWithBank =
      '''
    *,
    ${BanksTable.tableName} (
      ${BanksTable.name},
      ${BanksTable.icon}
    )
  ''';

  static const _selectPositions =
      '''
    ${UserInvestmentPositionTable.id},
    ${UserInvestmentPositionTable.userInvestmentAccountId},
    ${UserInvestmentPositionTable.quantity},
    ${UserInvestmentPositionTable.pru},
    ${PositionsTable.tableName}!inner(
      ${PositionsTable.id},
      ${PositionsTable.ticker},
      ${PositionsTable.name},
      ${PositionsTable.type},
      ${PositionsTable.price}
    )
  ''';

  // ─── Lecture ────────────────────────────────────────────────────────────────

  Future<List<UserInvestmentAccountView>>
  getInvestmentAccountsForUserWithPrices() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final response = await _supabase
          .from(UserInvestmentAccountTable.tableName)
          .select(_selectAccountsWithPrices)
          .eq(UserInvestmentAccountTable.userId, user.id);

      return response
          .map<UserInvestmentAccountView>(_mapToAccountView)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<UserInvestmentAccount>> getUserInvestmentAccounts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final response = await _supabase
        .from(UserInvestmentAccountTable.tableName)
        .select()
        .eq(UserInvestmentAccountTable.userId, user.id);

    return response
        .map<UserInvestmentAccount>((e) => UserInvestmentAccount.fromMap(e))
        .toList();
  }

  Future<List<UserInvestmentAccountView>>
  getUserInvestmentAccountsView() async {
    final uiaList = await getUserInvestmentAccounts();
    final List<UserInvestmentAccountView> views = [];

    for (final uia in uiaList) {
      final source = await _supabase
          .from(InvestmentSourceTable.tableName)
          .select(_selectSourceWithBank)
          .eq(InvestmentSourceTable.id, uia.investmentSourceId!)
          .single();

      final category = await _supabase
          .from(InvestmentCategoryTable.tableName)
          .select(InvestmentCategoryTable.name)
          .eq(
        InvestmentCategoryTable.id,
            source[InvestmentSourceTable.investmentCategoryId],
          )
          .single();

      final bank = source[BanksTable.tableName] as Map<String, dynamic>;
      final totalAmount = await getTotalValueOfInvestmentAccount(uia);

      views.add(
        UserInvestmentAccountView(
          id: uia.id,
          sourceName: category[InvestmentCategoryTable.name] as String,
          bankName: bank[BanksTable.name] as String,
          logoUrl: _resolveLogoUrl(bank[BanksTable.icon] as String?),
          totalContribution: uia.cumulativeDeposits,
          cashBalance: uia.cashBalance,
          amount: totalAmount,
        ),
      );
    }

    return views;
  }

  Future<List<InvestmentPosition>> getInvestmentPositions(
    int userInvestmentAccountId,
  ) async {
    final response = await _supabase
        .from(UserInvestmentPositionTable.tableName)
        .select(_selectPositions)
        .eq(
      UserInvestmentPositionTable.userInvestmentAccountId,
          userInvestmentAccountId,
        )
        .order(UserInvestmentPositionTable.createdAt);

    return response
        .map<InvestmentPosition>((e) => InvestmentPosition.fromMap(e))
        .toList();
  }

  // ─── Calculs ─────────────────────────────────────────────────────────────────

  Future<double> getUserInvestmentsTotalValue() async {
    final accounts = await getUserInvestmentAccounts();
    double total = 0.0;
    for (final account in accounts) {
      total += await getTotalValueOfInvestmentAccount(account);
    }
    return total;
  }

  Future<double> getTotalValueOfInvestmentAccount(
    UserInvestmentAccount account,
  ) async {
    final positionsValue = await getPositionsValueForAccount(account.id);
    return account.cashBalance + positionsValue;
  }

  Future<double> getPositionsValueForAccount(
    int userInvestmentAccountId,
  ) async {
    final positions = await getInvestmentPositions(userInvestmentAccountId);
    return positions.fold<double>(0.0, (sum, p) => sum + p.totalValue);
  }

  // ─── Écriture ────────────────────────────────────────────────────────────────

  Future<bool> updateInvestmentAccount({
    required int userInvestmentAccountId,
    required double cashBalance,
    required double cumulativeDeposits,
  }) async {
    final current = await _supabase
        .from(UserInvestmentAccountTable.tableName)
        .select(
          '${UserInvestmentAccountTable.cashBalance}, ${UserInvestmentAccountTable.totalContribution}',
        )
        .eq(UserInvestmentAccountTable.id, userInvestmentAccountId)
        .single();

    final currentCash =
        (current[UserInvestmentAccountTable.cashBalance] as num?)?.toDouble() ??
        0.0;
    final currentDeposits =
        (current[UserInvestmentAccountTable.totalContribution] as num?)
            ?.toDouble() ??
        0.0;

    if (currentCash == cashBalance && currentDeposits == cumulativeDeposits) {
      return false;
    }

    await _supabase
        .from(UserInvestmentAccountTable.tableName)
        .update({
          UserInvestmentAccountTable.cashBalance: cashBalance,
          UserInvestmentAccountTable.totalContribution: cumulativeDeposits,
          UserInvestmentAccountTable.updatedAt: DateTime.now().toIso8601String(),
        })
        .eq(UserInvestmentAccountTable.id, userInvestmentAccountId);

    return true;
  }

  Future<void> deleteUserInvestmentAccount(int accountId) async {
    await _supabase
        .from(UserInvestmentAccountTable.tableName)
        .delete()
        .eq(UserInvestmentAccountTable.id, accountId);
  }

  // ─── Helpers privés ──────────────────────────────────────────────────────────

  UserInvestmentAccountView _mapToAccountView(Map<String, dynamic> item) {
    final source =
        item[InvestmentSourceTable.tableName] as Map<String, dynamic>;
    final bank = source[BanksTable.tableName] as Map<String, dynamic>;
    final category =
        source[InvestmentCategoryTable.tableName] as Map<String, dynamic>;

    return UserInvestmentAccountView(
      id: item[UserInvestmentAccountTable.id] as int,
      sourceName: category[InvestmentCategoryTable.name] as String,
      bankName: bank[BanksTable.name] as String,
      logoUrl: _resolveLogoUrl(bank[BanksTable.icon] as String?),
      totalContribution:
          (item[UserInvestmentAccountTable.totalContribution] as num?)
              ?.toDouble() ??
          0.0,
      cashBalance:
          (item[UserInvestmentAccountTable.cashBalance] as num?)?.toDouble() ??
          0.0,
      amount:
          (item[UserInvestmentAccountTable.amount] as num?)?.toDouble() ?? 0.0,
    );
  }

  String _resolveLogoUrl(String? iconPath) {
    if (iconPath == null || iconPath.isEmpty) return '';
    return _supabase.storage
        .from(StorageBucketsTable.banksIcons)
        .getPublicUrl(iconPath);
  }
}