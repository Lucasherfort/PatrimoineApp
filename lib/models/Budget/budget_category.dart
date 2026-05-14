enum TransactionType { income, expense, perk }

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
    // Logique de mapping pour les 3 types
    TransactionType mappedType;
    switch (map['type']) {
      case 'income':
        mappedType = TransactionType.income;
        break;
      case 'perk':
        mappedType = TransactionType.perk;
        break;
      case 'expense':
      default:
        mappedType = TransactionType.expense;
    }

    return BudgetCategory(
      id: map['id'].toString(),
      name: map['name'],
      icon: map['icon'] ?? 'category',
      type: mappedType,
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

  Map<String, dynamic> toMap() {
    final map = {
      'user_id': userId,
      'category_id': categoryId,
      'value': value,
      'date': date.toIso8601String(),
      'note': note,
    };

    // Si l'ID existe (cas d'une mise à jour), on l'ajoute au map
    if (id != null) map['id'] = id;

    return map;
  }
}