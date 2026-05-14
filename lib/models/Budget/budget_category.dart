enum TransactionType { income, expense }

class BudgetCategory {
  final String id;
  final String name;
  final String icon;
  final TransactionType type;

  BudgetCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
  });

  factory BudgetCategory.fromMap(Map<String, dynamic> map) {
    return BudgetCategory(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      type: map['type'] == 'income' ? TransactionType.income : TransactionType.expense,
    );
  }
}

class BudgetTransaction {
  final String? id;
  final String userId;
  final String categoryId;
  final double value;
  final DateTime date;
  final String? note;

  BudgetTransaction({
    this.id,
    required this.userId,
    required this.categoryId,
    required this.value,
    required this.date,
    this.note,
  });

  // Pour envoyer vers Supabase
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'value': value,
      'date': date.toIso8601String(),
      'note': note,
    };
  }
}