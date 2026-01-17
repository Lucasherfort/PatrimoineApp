// lib/services/position_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/database_tables.dart';
import '../models/position.dart';

class PositionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Singleton
  static final PositionService _instance = PositionService._internal();
  factory PositionService() => _instance;
  PositionService._internal();


  /// Ajoute une nouvelle position utilisateur
  Future<void> addPosition({
    required int userInvestmentAccountId,
    required int positionId,
    required double quantity,
    required double averagePurchasePrice,
    int? positionCategoryId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      await _supabase.from(DatabaseTables.userInvestmentPosition).insert({
        'user_investment_account_id': userInvestmentAccountId,
        'position_id': positionId,
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

  /// Récupère toutes les positions disponibles dans la table positions
  Future<List<Position>> getAllPositions() async {
    final response = await _supabase
        .from(DatabaseTables.positions)
        .select()
        .order('ticker');

    return response.map<Position>((e) => Position.fromMap(e)).toList();
  }

  // Récupère une position par son id
  Future<Position?> getPosition(int positionId) async {
    // Requête sur la table positions pour récupérer la position par id
    final response = await _supabase
        .from(DatabaseTables.positions)
        .select()
        .eq('id', positionId)
        .maybeSingle(); // Renvoie null si aucun résultat

    if (response == null) return null;

    return Position.fromMap(response);
  }
  
}