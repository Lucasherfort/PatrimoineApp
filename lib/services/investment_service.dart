import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/database_columns.dart';
import '../bdd/database_tables.dart';
import '../bdd/storage_buckets.dart';
import '../models/investment_position.dart';
import '../models/investments/user_investment_account_view.dart';
import '../models/user_investment_account.dart';

class InvestmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static final InvestmentService _instance = InvestmentService._internal();
  factory InvestmentService() => _instance;
  InvestmentService._internal();

  // ─── Requêtes SELECT ────────────────────────────────────────────────────────

  static const _selectAccountsWithPrices = '''
    ${InvestmentAccountColumns.id},
    ${InvestmentAccountColumns.totalContribution},
    ${InvestmentAccountColumns.cashBalance},
    ${InvestmentAccountColumns.amount},
    ${DatabaseTables.investmentSource} (
      ${InvestmentSourceColumns.id},
      ${InvestmentSourceColumns.bankId},
      ${DatabaseTables.banks} (
        ${BankColumns.id},
        ${BankColumns.name},
        ${BankColumns.icon}
      ),
      ${DatabaseTables.investmentCategory} (
        ${InvestmentCategoryColumns.name}
      )
    )
  ''';

  static const _selectSourceWithBank = '''
    *,
    ${DatabaseTables.banks} (
      ${BankColumns.name},
      ${BankColumns.icon}
    )
  ''';

  static const _selectPositions = '''
    ${InvestmentPositionColumns.id},
    ${InvestmentPositionColumns.userInvestmentAccountId},
    ${InvestmentPositionColumns.quantity},
    ${InvestmentPositionColumns.pru},
    ${DatabaseTables.positions}!inner(
      ${PositionColumns.id},
      ${PositionColumns.ticker},
      ${PositionColumns.name},
      ${PositionColumns.type},
      ${PositionColumns.price}
    )
  ''';

  // ─── Lecture ────────────────────────────────────────────────────────────────

  Future<List<UserInvestmentAccountView>> getInvestmentAccountsForUserWithPrices() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final response = await _supabase
          .from(DatabaseTables.userInvestmentAccount)
          .select(_selectAccountsWithPrices)
          .eq(InvestmentAccountColumns.userId, user.id);

      return response.map<UserInvestmentAccountView>(_mapToAccountView).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<UserInvestmentAccount>> getUserInvestmentAccounts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final response = await _supabase
        .from(DatabaseTables.userInvestmentAccount)
        .select()
        .eq(InvestmentAccountColumns.userId, user.id);

    return response
        .map<UserInvestmentAccount>((e) => UserInvestmentAccount.fromMap(e))
        .toList();
  }

  Future<List<UserInvestmentAccountView>> getUserInvestmentAccountsView() async {
    final uiaList = await getUserInvestmentAccounts();
    final List<UserInvestmentAccountView> views = [];

    for (final uia in uiaList) {
      final source = await _supabase
          .from(DatabaseTables.investmentSource)
          .select(_selectSourceWithBank)
          .eq(InvestmentSourceColumns.id, uia.investmentSourceId!)
          .single();

      final category = await _supabase
          .from(DatabaseTables.investmentCategory)
          .select(InvestmentCategoryColumns.name)
          .eq(InvestmentCategoryColumns.id, source[InvestmentAccountColumns.investmentCategoryId])
          .single();

      final bank = source[DatabaseTables.banks] as Map<String, dynamic>;
      final totalAmount = await getTotalValueOfInvestmentAccount(uia);

      views.add(UserInvestmentAccountView(
        id: uia.id,
        sourceName: category[InvestmentCategoryColumns.name] as String,
        bankName: bank[BankColumns.name] as String,
        logoUrl: _resolveLogoUrl(bank[BankColumns.icon] as String?),
        totalContribution: uia.cumulativeDeposits,
        cashBalance: uia.cashBalance,
        amount: totalAmount,
      ));
    }

    return views;
  }

  Future<List<InvestmentPosition>> getInvestmentPositions(int userInvestmentAccountId) async {
    final response = await _supabase
        .from(DatabaseTables.userInvestmentPosition)
        .select(_selectPositions)
        .eq(InvestmentPositionColumns.userInvestmentAccountId, userInvestmentAccountId)
        .order(InvestmentPositionColumns.createdAt);

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

  Future<double> getTotalValueOfInvestmentAccount(UserInvestmentAccount account) async {
    final positionsValue = await getPositionsValueForAccount(account.id);
    return account.cashBalance + positionsValue;
  }

  Future<double> getPositionsValueForAccount(int userInvestmentAccountId) async {
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
        .from(DatabaseTables.userInvestmentAccount)
        .select('${InvestmentAccountColumns.cashBalance}, ${InvestmentAccountColumns.totalContribution}')
        .eq(InvestmentAccountColumns.id, userInvestmentAccountId)
        .single();

    final currentCash = (current[InvestmentAccountColumns.cashBalance] as num?)?.toDouble() ?? 0.0;
    final currentDeposits = (current[InvestmentAccountColumns.totalContribution] as num?)?.toDouble() ?? 0.0;

    if (currentCash == cashBalance && currentDeposits == cumulativeDeposits) return false;

    await _supabase
        .from(DatabaseTables.userInvestmentAccount)
        .update({
      InvestmentAccountColumns.cashBalance: cashBalance,
      InvestmentAccountColumns.totalContribution: cumulativeDeposits,
      InvestmentAccountColumns.updatedAt: DateTime.now().toIso8601String(),
    })
        .eq(InvestmentAccountColumns.id, userInvestmentAccountId);

    return true;
  }

  Future<void> deleteUserInvestmentAccount(int accountId) async {
    await _supabase
        .from(DatabaseTables.userInvestmentAccount)
        .delete()
        .eq(InvestmentAccountColumns.id, accountId);
  }

  // ─── Helpers privés ──────────────────────────────────────────────────────────

  UserInvestmentAccountView _mapToAccountView(Map<String, dynamic> item) {
    final source = item[DatabaseTables.investmentSource] as Map<String, dynamic>;
    final bank = source[DatabaseTables.banks] as Map<String, dynamic>;
    final category = source[DatabaseTables.investmentCategory] as Map<String, dynamic>;

    return UserInvestmentAccountView(
      id: item[InvestmentAccountColumns.id] as int,
      sourceName: category[InvestmentCategoryColumns.name] as String,
      bankName: bank[BankColumns.name] as String,
      logoUrl: _resolveLogoUrl(bank[BankColumns.icon] as String?),
      totalContribution: (item[InvestmentAccountColumns.totalContribution] as num?)?.toDouble() ?? 0.0,
      cashBalance: (item[InvestmentAccountColumns.cashBalance] as num?)?.toDouble() ?? 0.0,
      amount: (item[InvestmentAccountColumns.amount] as num?)?.toDouble() ?? 0.0,
    );
  }

  String _resolveLogoUrl(String? iconPath) {
    if (iconPath == null || iconPath.isEmpty) return '';
    return _supabase.storage.from(StorageBuckets.banksIcons).getPublicUrl(iconPath);
  }
}