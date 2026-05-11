import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/positions_table.dart';
import '../bdd/user_investment_position_table.dart';
import '../models/position.dart';

class PositionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static final PositionService _instance = PositionService._internal();
  factory PositionService() => _instance;
  PositionService._internal();

  // ─── Lecture ──────────────────────────────────────────────────────────────

  Future<List<Position>> getAllPositions() async {
    final response = await _supabase
        .from(PositionsTable.tableName)
        .select()
        .order(PositionsTable.name, ascending: true);

    return response.map<Position>((e) => Position.fromMap(e)).toList();
  }

  Future<Position?> getPosition(int positionId) async {
    final response = await _supabase
        .from(PositionsTable.tableName)
        .select()
        .eq(PositionsTable.id, positionId)
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

    await _supabase.from(UserInvestmentPositionTable.tableName).insert({
      UserInvestmentPositionTable.userInvestmentAccountId:
          userInvestmentAccountId,
      UserInvestmentPositionTable.positionId: positionId,
      UserInvestmentPositionTable.positionCategoryId: positionCategoryId,
      UserInvestmentPositionTable.quantity: quantity,
      UserInvestmentPositionTable.pru: averagePurchasePrice,
    });
  }

  Future<bool> updatePosition({
    required int positionId,
    required double quantity,
    required double pru,
  }) async {
    final response = await _supabase
        .from(UserInvestmentPositionTable.tableName)
        .update({
          UserInvestmentPositionTable.quantity: quantity,
          UserInvestmentPositionTable.pru: pru,
          UserInvestmentPositionTable.updatedAt: DateTime.now()
              .toUtc()
              .toIso8601String(),
        })
        .eq(UserInvestmentPositionTable.id, positionId)
        .select();

    return response.isNotEmpty;
  }

  Future<void> deletePosition(int positionId) async {
    await _supabase
        .from(UserInvestmentPositionTable.tableName)
        .delete()
        .eq(UserInvestmentPositionTable.id, positionId);
  }
}
