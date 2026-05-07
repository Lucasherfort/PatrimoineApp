import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/database_columns.dart';
import '../bdd/database_tables.dart';
import '../models/position.dart';

class PositionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static final PositionService _instance = PositionService._internal();
  factory PositionService() => _instance;
  PositionService._internal();

  // ─── Lecture ──────────────────────────────────────────────────────────────

  Future<List<Position>> getAllPositions() async {
    final response = await _supabase
        .from(DatabaseTables.positions)
        .select()
        .order(PositionColumns.name, ascending: true);

    return response.map<Position>((e) => Position.fromMap(e)).toList();
  }

  Future<Position?> getPosition(int positionId) async {
    final response = await _supabase
        .from(DatabaseTables.positions)
        .select()
        .eq(PositionColumns.id, positionId)
        .maybeSingle();

    return response != null ? Position.fromMap(response) : null;
  }

  // ─── Écriture ─────────────────────────────────────────────────────────────

  Future<void> addPosition({
    required int userInvestmentAccountId,
    required int positionId,
    required double quantity,
    required double averagePurchasePrice,
    int? positionCategoryId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    await _supabase.from(DatabaseTables.userInvestmentPosition).insert({
      UserInvestmentPositionColumns.userInvestmentAccountId: userInvestmentAccountId,
      UserInvestmentPositionColumns.positionId: positionId,
      UserInvestmentPositionColumns.positionCategoryId: positionCategoryId,
      UserInvestmentPositionColumns.quantity: quantity,
      UserInvestmentPositionColumns.pru: averagePurchasePrice,
    });
  }

  Future<bool> updatePosition({
    required int positionId,
    required double quantity,
    required double pru,
  }) async {
    final response = await _supabase
        .from(DatabaseTables.userInvestmentPosition)
        .update({
      UserInvestmentPositionColumns.quantity: quantity,
      UserInvestmentPositionColumns.pru: pru,
      UserInvestmentPositionColumns.updatedAt: DateTime.now().toUtc().toIso8601String(),
    })
        .eq(UserInvestmentPositionColumns.id, positionId)
        .select();

    return response.isNotEmpty;
  }

  Future<void> deletePosition(int positionId) async {
    await _supabase
        .from(DatabaseTables.userInvestmentPosition)
        .delete()
        .eq(UserInvestmentPositionColumns.id, positionId);
  }
}