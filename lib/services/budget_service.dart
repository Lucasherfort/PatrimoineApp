import 'package:supabase_flutter/supabase_flutter.dart';
import '../bdd/budget_category_table.dart';
import '../bdd/budget_item_table.dart';
import '../models/budget/budget_category.dart';
import '../models/budget/budget_item.dart';

class BudgetService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  // ─── Catégories ───────────────────────────────────────────────────────────

  Future<List<BudgetCategory>> getCategories() async {
    final response = await _supabase
        .from(BudgetCategoryTable.tableName)
        .select()
        .order(BudgetCategoryTable.label);

    return response.map((m) => BudgetCategory.fromMap(m)).toList();
  }

  // ─── Items ────────────────────────────────────────────────────────────────

  Future<List<BudgetItem>> getBudgetItems() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from(BudgetItemTable.tableName)
        .select('*, ${BudgetCategoryTable.tableName}(*)')
        .eq(BudgetItemTable.userId, user.id)
        .order(BudgetItemTable.createdAt);

    return response.map((m) => BudgetItem.fromMap(m)).toList();
  }

  Future<void> addBudgetItem({
    required String? categoryId,
    required String label,
    required double amount,
    bool isRecurring = true,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from(BudgetItemTable.tableName).insert({
      BudgetItemTable.userId: user.id,
      BudgetItemTable.categoryId: categoryId,
      BudgetItemTable.label: label,
      BudgetItemTable.amount: amount,
      BudgetItemTable.isRecurring: isRecurring,
    });
  }

  Future<void> updateBudgetItem({
    required String id,
    required String? categoryId,
    required String label,
    required double amount,
    bool isRecurring = true,
  }) async {
    await _supabase
        .from(BudgetItemTable.tableName)
        .update({
          BudgetItemTable.categoryId: categoryId,
          BudgetItemTable.label: label,
          BudgetItemTable.amount: amount,
          BudgetItemTable.isRecurring: isRecurring,
        })
        .eq('id', id);
  }

  Future<void> deleteBudgetItem(String id) async {
    await _supabase.from(BudgetItemTable.tableName).delete().eq('id', id);
  }

  // ─── Calculs ──────────────────────────────────────────────────────────────

  Future<double> getTotalIncomings() async {
    final items = await getBudgetItems();
    return items
        .where((i) => i.category?.type == BudgetType.income)
        .fold<double>(0.0, (sum, i) => sum + i.amount);
  }

  Future<double> getTotalOutgoings() async {
    final items = await getBudgetItems();
    return items
        .where((i) => i.category?.type == BudgetType.expense)
        .fold<double>(0.0, (sum, i) => sum + i.amount);
  }

  Future<double> getTotalEssentialExpenses() async {
    final items = await getBudgetItems();
    return items
        .where(
          (i) =>
              i.category?.type == BudgetType.expense &&
              i.category?.isEssential == true,
        )
        .fold<double>(0.0, (sum, i) => sum + i.amount);
  }

  Future<double> getMonthlySavingsCapacity() async {
    final incoming = await getTotalIncomings();
    final outgoing = await getTotalOutgoings();
    return incoming - outgoing;
  }
}
