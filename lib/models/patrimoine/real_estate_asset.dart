class RealEstateAsset {
  final int id;
  final int categoryId;
  final String categoryName;
  final String label;
  final double amount;
  final String? address;

  RealEstateAsset({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.label,
    required this.amount,
    this.address,
  });

  factory RealEstateAsset.fromJson(Map<String, dynamic> json) {
    dynamic catRaw = json['real_estate_category'];
    final category = catRaw is List
        ? catRaw.first
        : catRaw as Map<String, dynamic>?;

    return RealEstateAsset(
      id: json['id'],
      categoryId: json['category_id'],
      categoryName: category != null
          ? (category['label'] ?? category['name'] ?? 'Inconnu')
          : 'Inconnu',
      label: json['label'],
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      address: json['address'],
    );
  }
}
