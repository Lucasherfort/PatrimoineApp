import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/Budget/budget_category.dart';

class BudgetService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- CATÉGORIES ---

  /// Récupère toutes les catégories (Revenus et Dépenses)
  Future<List<BudgetCategory>> getCategories() async {
    try {
      final response = await _supabase
          .from('budget_category')
          .select()
          .order('name');

      return (response as List)
          .map((json) => BudgetCategory.fromMap(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des catégories: $e');
    }
  }

  // --- TRANSACTIONS ---

  /// Ajouter une nouvelle transaction
  Future<void> addTransaction(BudgetTransaction transaction) async {
    try {
      await _supabase.from('transaction').insert(transaction.toMap());
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la transaction: $e');
    }
  }

  /// Modifier une transaction existante
  Future<void> updateTransaction(
    String id,
    BudgetTransaction transaction,
  ) async {
    try {
      await _supabase.from('transaction').update(transaction.toMap()).match({
        'id': id,
      });
    } catch (e) {
      throw Exception('Erreur lors de la modification : $e');
    }
  }

  /// Supprimer une transaction
  Future<void> deleteTransaction(String id) async {
    try {
      await _supabase.from('transaction').delete().match({'id': id});
    } catch (e) {
      throw Exception('Erreur lors de la suppression : $e');
    }
  }

  /// Récupérer les transactions du mois en cours avec les données de catégorie
  Future<List<Map<String, dynamic>>> getMonthlyTransactions() async {
    final user = _supabase.auth.currentUser; // <--- Récupère l'utilisateur
    if (user == null) return []; // Sécurité si non connecté

    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1).toIso8601String();
    final lastDay = DateTime(now.year, now.month + 1, 0, 23, 59, 59).toIso8601String();

    try {
      final List<dynamic> response = await _supabase
          .from('transaction')
          .select('*, budget_category(*)')
          .eq('user_id', user.id) // <--- AJOUTE CE FILTRE ICI
          .gte('date', firstDay)
          .lte('date', lastDay)
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des transactions: $e');
    }
  }
}
