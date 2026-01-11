// lib/models/patrimoine_source.dart
class PatrimoineSource {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final String? entityType;

  PatrimoineSource({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    this.entityType,
  });

  factory PatrimoineSource.fromDatabase(Map<String, dynamic> row) {
    return PatrimoineSource(
      id: row['id'] as int,
      categoryId: row['category_id'] as int,
      name: row['name'] as String,
      description: row['description'] as String? ?? '',
      entityType: row['entity_type'] as String?,
    );
  }

  String get label => description.isNotEmpty ? description : name;
}