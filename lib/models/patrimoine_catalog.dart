import 'patrimoine_category.dart';
import 'patrimoine_type.dart';

class PatrimoineCatalog {
  final List<PatrimoineCategory> categories;
  final List<PatrimoineType> types;

  PatrimoineCatalog({
    required this.categories,
    required this.types,
  });

  factory PatrimoineCatalog.fromJson(Map<String, dynamic> json) {
    return PatrimoineCatalog(
      categories: (json['categories'] as List)
          .map((c) => PatrimoineCategory.fromJson(c))
          .toList(),
      types: (json['types'] as List)
          .map((t) => PatrimoineType.fromJson(t))
          .toList(),
    );
  }

  /// 🔎 Types par catégorie
  List<PatrimoineType> getTypesForCategory(int categoryId) {
    return types.where((t) => t.categoryId == categoryId).toList();
  }

  PatrimoineCategory? getCategoryById(int id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  PatrimoineType? getTypeById(int id) {
    try {
      return types.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
