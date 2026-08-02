import 'budget_category.dart';

class BudgetItem {
  final String id;
  final String userId;
  final String? categoryId;
  final String label;
  final double amount;
  final bool isRecurring;

  // Jointure optionnelle
  final BudgetCategory? category;

  BudgetItem({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.label,
    required this.amount,
    this.isRecurring = true,
    this.category,
  });

  factory BudgetItem.fromMap(Map<String, dynamic> map) {
    return BudgetItem(
      id: map['id'],
      userId: map['user_id'],
      categoryId: map['category_id'],
      label: map['label'],
      amount: (map['amount'] as num).toDouble(),
      isRecurring: map['is_recurring'] ?? true,
      category: map['budget_category'] != null
          ? BudgetCategory.fromMap(map['budget_category'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category_id': categoryId,
      'label': label,
      'amount': amount,
      'is_recurring': isRecurring,
      'user_id': userId,
    };
  }
}
