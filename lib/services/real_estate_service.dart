import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/user_real_estate_asset_table.dart';
import '../bdd/real_estate_category_table.dart';
import '../models/patrimoine/real_estate_asset.dart';

class RealEstateService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static final RealEstateService _instance = RealEstateService._internal();
  factory RealEstateService() => _instance;
  RealEstateService._internal();

  String _requireUserId() {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');
    return user.id;
  }

  Future<List<RealEstateAsset>> getUserRealEstateAssets() async {
    final userId = _requireUserId();

    final response = await _supabase
        .from(UserRealEstateAssetTable.tableName)
        .select('*, ${RealEstateCategoryTable.tableName}(*)')
        .eq(UserRealEstateAssetTable.userId, userId)
        .order(UserRealEstateAssetTable.createdAt);

    return (response as List)
        .map((json) => RealEstateAsset.fromJson(json))
        .toList();
  }

  Future<void> updateAsset({
    required int assetId,
    double? amount,
    String? label,
  }) async {
    final Map<String, dynamic> updates = {
      UserRealEstateAssetTable.updatedAt: DateTime.now().toIso8601String(),
    };
    if (amount != null) {
      updates[UserRealEstateAssetTable.amount] = amount;
    }
    if (label != null) {
      updates[UserRealEstateAssetTable.label] = label;
    }
    await _supabase
        .from(UserRealEstateAssetTable.tableName)
        .update(updates)
        .eq(UserRealEstateAssetTable.id, assetId);
  }

  Future<void> updateAssetAmount(int assetId, double amount) async {
    await updateAsset(assetId: assetId, amount: amount);
  }

  Future<void> updateAssetLabel(int assetId, String label) async {
    await updateAsset(assetId: assetId, label: label);
  }

  Future<void> deleteAsset(int assetId) async {
    await _supabase
        .from(UserRealEstateAssetTable.tableName)
        .delete()
        .eq(UserRealEstateAssetTable.id, assetId);
  }

  Future<double> getTotalRealEstateValue() async {
    final assets = await getUserRealEstateAssets();
    double total = 0.0;
    for (var asset in assets) {
      total += asset.amount;
    }
    return total;
  }
}
