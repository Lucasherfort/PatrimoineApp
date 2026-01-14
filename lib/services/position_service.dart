// lib/services/position_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/database_tables.dart';
import '../models/investment_position.dart';
import 'google_sheet_service.dart';

class PositionService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSheetsService _sheetsService = GoogleSheetsService();

  // Singleton
  static final PositionService _instance = PositionService._internal();
  factory PositionService() => _instance;
  PositionService._internal();

  /// Récupère les positions d'un compte (sans mise à jour des prix)
  Future<List<InvestmentPosition>> getPositionsForAccount(int accountId) async {
    final response = await _supabase
        .from(DatabaseTables.userInvestmentPosition)
        .select()
        .eq('user_investment_account_id', accountId)
        .order('created_at');

    return response
        .map<InvestmentPosition>((e) => InvestmentPosition.fromMap(e))
        .toList();
  }

  /// Récupère les positions d'un compte ET les met à jour avec Google Sheets
  Future<List<InvestmentPosition>> getInvestmentPositions(int userInvestmentAccountId) async {
    final positions = await getPositionsForAccount(userInvestmentAccountId);

    if (positions.isEmpty) {
      return positions;
    }

    try {
      // Lecture Google Sheet
      final etfsData = await _sheetsService.fetchEtfs();

      // Indexation par ticker
      final Map<String, Map<String, dynamic>> etfsMap = {};
      for (final etf in etfsData) {
        final ticker = etf['ticker']?.toString().toUpperCase();
        if (ticker != null) {
          etfsMap[ticker] = etf;
        }
      }

      // Mise à jour des positions avec les données Sheet
      for (final position in positions) {
        final etfData = etfsMap[position.ticker.toUpperCase()];
        if (etfData != null) {
          position.updateFromSheet(etfData);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Erreur lors de la récupération des données Google Sheets: $e',
        );
      }
    }

    return positions;
  }

  /// Ajoute une nouvelle position
  Future<void> addPosition({
    required int userInvestmentAccountId,
    required String ticker,
    required String name,
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
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Met à jour une position existante et retourne true si modifiée
  Future<bool> updatePosition({
    required int positionId,
    required double quantity,
    required double pru,
  }) async {
    try {
      final response = await _supabase
          .from(DatabaseTables.userInvestmentPosition)
          .update({
        'quantity': quantity,
        'pru': pru,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      })
          .eq('id', positionId)
          .select();

      return response.isNotEmpty;
    } catch (e) {
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
      rethrow;
    }
  }

  /// Récupère la valeur totale des positions d'un compte
  Future<double> getPositionsValueForAccount(int userInvestmentAccountId) async {
    final positions = await getInvestmentPositions(userInvestmentAccountId);

    double result = 0.0;
    for (final position in positions) {
      result += position.totalValue;
    }

    return result;
  }
}