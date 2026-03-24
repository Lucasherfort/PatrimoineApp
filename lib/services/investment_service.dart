// lib/services/investment_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/database_tables.dart';
import '../models/investment_position.dart';
import '../models/investments/user_investment_account_view.dart';
import '../models/user_investment_account.dart';

class InvestmentService {
  // Création interne de GoogleSheetsService
  final SupabaseClient _supabase = Supabase.instance.client;

  // Singleton classique
  static final InvestmentService _instance = InvestmentService._internal();
  factory InvestmentService() => _instance;
  InvestmentService._internal();

  /// Récupère tous les comptes investissements de l'utilisateur
  Future<List<UserInvestmentAccountView>>
  getInvestmentAccountsForUserWithPrices() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final response = await _supabase
          .from(DatabaseTables.userInvestmentAccount)
          .select('''
          id,
          total_contribution,
          cash_balance,
          amount,
          investment_source (
            id,
            bank_id,
            banks (id, name, icon),
            investment_category (name)
          )
        ''')
          .eq('user_id', user.id);

      return response.map<UserInvestmentAccountView>((item) {
        final source = item['investment_source'];
        final bank = source['banks'];
        final category = source['investment_category'];

        // Construire l'URL publique complète pour l'icône
        final iconPath = bank['icon'] as String?;
        String logoUrl = '';
        if (iconPath != null && iconPath.isNotEmpty) {
          logoUrl = _supabase.storage
              .from('banks-icons')
              .getPublicUrl(iconPath);
        }

        return UserInvestmentAccountView(
          id: item['id'] as int,
          sourceName: category['name'] as String,
          bankName: bank['name'] as String,
          logoUrl: logoUrl, // 👈 Ajout du logo
          totalContribution:
              (item['total_contribution'] as num?)?.toDouble() ?? 0.0,
          cashBalance: (item['cash_balance'] as num?)?.toDouble() ?? 0.0,
          amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Met à jour un compte investissement
  Future<bool> updateInvestmentAccount({
    required int userInvestmentAccountId,
    required double cashBalance,
    required double cumulativeDeposits,
  }) async {
    try {
      // Récupérer les valeurs actuelles
      final current = await _supabase
          .from(DatabaseTables.userInvestmentAccount)
          .select('cash_balance, total_contribution')
          .eq('id', userInvestmentAccountId)
          .single();

      final currentCash = (current['cash_balance'] as num?)?.toDouble() ?? 0.0;
      final currentDeposits =
          (current['total_contribution'] as num?)?.toDouble() ?? 0.0;

      // Vérifier s'il y a un changement
      if (currentCash == cashBalance && currentDeposits == cumulativeDeposits) {
        return false; // Aucun changement
      }

      // Mettre à jour
      await _supabase
          .from(DatabaseTables.userInvestmentAccount)
          .update({
            'cash_balance': cashBalance,
            'total_contribution': cumulativeDeposits,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userInvestmentAccountId);

      return true; // Changement effectué
    } catch (e) {
      rethrow;
    }
  }

  /// Supprime un compte investissement (les positions seront supprimées en cascade)
  Future<void> deleteUserInvestmentAccount(int accountId) async {
    try {
      await _supabase
          .from(DatabaseTables.userInvestmentAccount)
          .delete()
          .eq('id', accountId);
    } catch (e) {
      rethrow;
    }
  }

  /// Récupère la valeur totale de tous les comptes d'investissement d'un utilisateur
  Future<double> getUserInvestmentsTotalValue() async {
    final uias = await getUserInvestmentAccounts();

    double totalValue = 0.0;

    for (final account in uias) {
      totalValue += await getTotalValueOfInvestmentAccount(account);
    }

    return totalValue;
  }

  Future<List<UserInvestmentAccount>> getUserInvestmentAccounts() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await _supabase
          .from(DatabaseTables.userInvestmentAccount)
          .select()
          .eq('user_id', user.id);

      return response
          .map<UserInvestmentAccount>((e) => UserInvestmentAccount.fromMap(e))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Récupère la valeur totale d'un compte d'investissement (espèces + titres)
  Future<double> getTotalValueOfInvestmentAccount(
    UserInvestmentAccount account,
  ) async {
    final positionsValue = await getPositionsValueForAccount(account.id);
    return account.cashBalance + positionsValue;
  }

  /// Récupère la valeur totale des positions d'un compte
  Future<double> getPositionsValueForAccount(
    int userInvestmentAccountId,
  ) async {
    // Les positions sont DÉJÀ à jour via Google Sheet
    final positions = await getInvestmentPositions(userInvestmentAccountId);

    double result = 0.0;
    for (final position in positions) {
      result += position.totalValue;
    }

    return result;
  }

  Future<List<UserInvestmentAccountView>>
  getUserInvestmentAccountsView() async {
    final uiaList = await getUserInvestmentAccounts();
    final List<UserInvestmentAccountView> views = [];

    for (final uia in uiaList) {
      // Récupérer la source avec la banque et son icône
      final source = await _supabase
          .from(DatabaseTables.investmentSource)
          .select('''
          *,
          banks (name, icon)
        ''')
          .eq('id', uia.investmentSourceId!)
          .single();

      // Récupérer le type de compte / catégorie
      final category = await _supabase
          .from(DatabaseTables.investmentCategory)
          .select('name')
          .eq('id', source['investment_category_id'])
          .single();

      // Construire l'URL publique complète pour l'icône
      final bank = source['banks'];
      final iconPath = bank['icon'] as String?;
      String logoUrl = '';
      if (iconPath != null && iconPath.isNotEmpty) {
        logoUrl = _supabase.storage.from('banks-icons').getPublicUrl(iconPath);
      }

      // Calculer la valeur totale du compte (cash + positions)
      final totalAmount = await getTotalValueOfInvestmentAccount(uia);

      views.add(
        UserInvestmentAccountView(
          id: uia.id,
          sourceName: category['name'] as String,
          bankName: bank['name'] as String,
          logoUrl: logoUrl, // 👈 Ajout du logo
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
        .from(DatabaseTables.userInvestmentPosition)
        .select('''
        id,
        user_investment_account_id,
        quantity,
        pru,
        positions!inner(
          id,
          ticker,
          name,
          type,
          price
        )
      ''')
        .eq('user_investment_account_id', userInvestmentAccountId)
        .order('created_at');

    return response
        .map<InvestmentPosition>((e) => InvestmentPosition.fromMap(e))
        .toList();
  }
}
