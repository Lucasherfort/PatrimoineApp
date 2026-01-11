import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/database_tables.dart';
import '../models/bank.dart';
import '../models/patrimoine/patrimoine_category.dart';
import '../models/restaurant_voucher.dart';

class PatrimoineService {
  // ✅ Le service gère Supabase en interne
  final SupabaseClient _supabase = Supabase.instance.client;

  // ✅ Singleton pour éviter les multiples instances
  static final PatrimoineService _instance = PatrimoineService._internal();
  factory PatrimoineService() => _instance;
  PatrimoineService._internal();

  /// Récupère le total patrimoine du user connecté
  Future<double> getPatrimoine() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    try {
      // ✅ Requête SQL classique au lieu de RPC
      final response = await _supabase
          .from(DatabaseTables.userLiquidityAccounts) // nom de votre table
          .select('amount') // ou la colonne appropriée
          .eq('user_id', user.id);

      // Calculer le total côté client
      double total = 0.0;
      for (var item in response)
      {
        total += (item['amount'] as num).toDouble();
      }

      return total;
    } catch (e) {
      print('Erreur getPatrimoine: $e');
      rethrow;
    }
  }

  /// Récupère toutes les catégories de patrimoine
  Future<List<PatrimoineCategory>> getPatrimoineCategories() async {
    try {
      // ✅ Vérifier l'utilisateur connecté
      final user = _supabase.auth.currentUser;
      print('User connecté: ${user?.id ?? "NON CONNECTÉ"}');

      final response = await _supabase
          .from(DatabaseTables.patrimoineCategory)
          .select('id, name, label')
          .order('name');

      if (response.isEmpty)
      {
        return [];
      }

      return response.map((item) => PatrimoineCategory(
        id: item['id'] as int,
        name: item['name'] as String,
        label: item['label'] as String? ?? '',
      )).toList();
    } catch (e)
    {
      rethrow;
    }
  }

  /// Récupère les banques pour un type
  Future<List<Bank>> getBanksForType(int typeId) async {
    try {
      final response = await _supabase
          .from('banks')
          .select('id, name')
          .eq('type_id', typeId) // ou la condition appropriée selon votre schéma
          .order('name');

      return response.map((item) => Bank(
        id: item['id'] as int,
        name: item['name'] as String,
      )).toList();
    } catch (e)
    {
      rethrow;
    }
  }

  /// Récupère les titres restaurant
  Future<List<RestaurantVoucher>> getRestaurantVouchers() async {
    try {
      final response = await _supabase
          .from('restaurant_vouchers')
          .select('id, name')
          .order('name');

      return response.map((item) => RestaurantVoucher(
        id: item['id'] as int,
        name: item['name'] as String,
      )).toList();
    } catch (e)
    {
      rethrow;
    }
  }
}