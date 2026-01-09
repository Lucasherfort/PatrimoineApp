class PatrimoineType {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final String entityType;

  PatrimoineType({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.entityType,
  });

  factory PatrimoineType.fromJson(Map<String, dynamic> json) {
    return PatrimoineType(
      id: json['id'],
      categoryId: json['categoryId'],
      name: json['name'],
      description: json['description'],
      entityType: json['entityType'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'categoryId': categoryId,
    'name': name,
    'description': description,
    'entityType': entityType,
  };
}
