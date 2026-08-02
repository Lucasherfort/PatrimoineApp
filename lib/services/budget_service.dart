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

  Future<void> deleteBudgetItem(String id) async {
    await _supabase.from(BudgetItemTable.tableName).delete().eq('id', id);
  }

  // ─── Calculs ──────────────────────────────────────────────────────────────

  Future<double> getMonthlySavingsCapacity() async {
    final items = await getBudgetItems();
    double income = 0;
    double expense = 0;

    for (var item in items) {
      if (item.category?.type == BudgetType.income) {
        income += item.amount;
      } else if (item.category?.type == BudgetType.expense) {
        expense += item.amount;
      }
    }

    return income - expense;
  }
}
