// lib/models/source_item.dart
class SourceItem {
  final int id;
  final String name;
  final String type; // 'liquidity' ou 'savings'
  final int? categoryId;
  final int? bankId;
  final double? interestRate; // Pour savings_category
  final double? ceiling; // Pour savings_category

  SourceItem({
    required this.id,
    required this.name,
    required this.type,
    this.categoryId,
    this.bankId,
    this.interestRate,
    this.ceiling,
  });

  String get label => name;

  factory SourceItem.fromLiquiditySource(Map<String, dynamic> row) {
    return SourceItem(
      id: row['id'] as int,
      name: row['name'] as String,
      type: 'liquidity',
      categoryId: row['category_id'] as int?,
      bankId: row['bank_id'] as int?,
    );
  }

  factory SourceItem.fromSavingsCategory(Map<String, dynamic> row) {
    return SourceItem(
      id: row['id'] as int,
      name: row['name'] as String,
      type: 'savings',
      interestRate: row['interest_rate'] != null ? (row['interest_rate'] as num).toDouble() : null,
      ceiling: row['ceiling'] != null ? (row['ceiling'] as num).toDouble() : null,
    );
  }

  factory SourceItem.fromInvestmentCategory(Map<String, dynamic> row) {
    return SourceItem(
      id: row['id'] as int,
      name: row['name'] as String,
      type: 'investment',
    );
  }
}