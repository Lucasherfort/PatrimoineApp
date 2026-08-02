enum BudgetType { income, expense }

class BudgetCategory {
  final String id;
  final String name;
  final String label;
  final String icon;
  final BudgetType type;
  final bool isDefault;

  BudgetCategory({
    required this.id,
    required this.name,
    required this.label,
    required this.icon,
    required this.type,
    this.isDefault = true,
  });

  factory BudgetCategory.fromMap(Map<String, dynamic> map) {
    return BudgetCategory(
      id: map['id'],
      name: map['name'],
      label: map['label'],
      icon: map['icon'] ?? 'help_outline',
      type: map['type'] == 'income' ? BudgetType.income : BudgetType.expense,
      isDefault: map['is_default'] ?? true,
    );
  }
}
