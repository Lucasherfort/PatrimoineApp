// lib/services/investment_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/database_tables.dart';
import '../models/investments/UserInvestmentAccountView.dart';
import '../models/investment_position.dart';

class InvestmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static final InvestmentService _instance = InvestmentService._internal();
  factory InvestmentService() => _instance;
  InvestmentService._internal();

  /// Récupère tous les comptes investissements de l'utilisateur
  Future<List<UserInvestmentAccountView>> getInvestmentAccountsForUserWithPrices() async {
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
              banks (id, name),
              investment_category (name)
            )
          ''')
          .eq('user_id', user.id);

      return response.map<UserInvestmentAccountView>((item) {
        final source = item['investment_source'];
        final bank = source['banks'];
        final category = source['investment_category'];

        return UserInvestmentAccountView(
          id: item['id'] as int,
          sourceName: category['name'] as String,
          bankName: bank['name'] as String,
          totalContribution: (item['total_contribution'] as num?)?.toDouble() ?? 0.0,
          cashBalance: (item['cash_balance'] as num?)?.toDouble() ?? 0.0,
          amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (e) {
      print('Erreur getInvestmentAccountsForUserWithPrices: $e');
      return [];
    }
  }

  /// Récupère les positions d'un compte investissement
  Future<List<InvestmentPosition>> getInvestmentPositions(
      int userInvestmentAccountId
      ) async {
    try {
      final response = await _supabase
          .from(DatabaseTables.userInvestmentPosition)
          .select('*')
          .eq('user_investment_account_id', userInvestmentAccountId)
          .order('ticker');

      return response.map<InvestmentPosition>(
              (item) => InvestmentPosition.fromDatabase(item)
      ).toList();
    } catch (e) {
      print('Erreur getInvestmentPositions: $e');
      rethrow;
    }
  }

  /// Ajoute une nouvelle position
  Future<void> addPosition({
    required int userInvestmentAccountId,
    required String ticker,
    required String name, // Sera stocké en mémoire, pas en BDD
    required double quantity,
    required double averagePurchasePrice,
    int? positionCategoryId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await _supabase.from(DatabaseTables.userInvestmentPosition).insert({
        'user_investment_account_id': userInvestmentAccountId,
        'ticker': ticker.toUpperCase(),
        'position_category_id': positionCategoryId,
        'quantity': quantity,
        'pru': averagePurchasePrice,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Erreur addPosition: $e');
      rethrow;
    }
  }

  /// Met à jour une position existante
  Future<void> updatePosition({
    required int positionId,
    required double quantity,
    required double averagePurchasePrice,
    int? positionCategoryId,
  }) async {
    try {
      await _supabase.from(DatabaseTables.userInvestmentPosition).update({
        'quantity': quantity,
        'pru': averagePurchasePrice,
        'position_category_id': positionCategoryId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', positionId);
    } catch (e) {
      print('Erreur updatePosition: $e');
      rethrow;
    }
  }

  /// Supprime une position
  Future<void> deletePosition(int positionId) async {
    try {
      await _supabase
          .from(DatabaseTables.userInvestmentPosition)
          .delete()
          .eq('id', positionId);
    } catch (e) {
      print('Erreur deletePosition: $e');
      rethrow;
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
          .select('cash_balance, cumulative_deposits')
          .eq('id', userInvestmentAccountId)
          .single();

      final currentCash = (current['cash_balance'] as num?)?.toDouble() ?? 0.0;
      final currentDeposits = (current['cumulative_deposits'] as num?)?.toDouble() ?? 0.0;

      // Vérifier s'il y a un changement
      if (currentCash == cashBalance && currentDeposits == cumulativeDeposits) {
        return false; // Aucun changement
      }

      // Mettre à jour
      await _supabase.from(DatabaseTables.userInvestmentAccount).update({
        'cash_balance': cashBalance,
        'cumulative_deposits': cumulativeDeposits,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userInvestmentAccountId);

      return true; // Changement effectué
    } catch (e) {
      print('Erreur updateInvestmentAccount: $e');
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
      print('Erreur deleteUserInvestmentAccount: $e');
      rethrow;
    }
  }
}