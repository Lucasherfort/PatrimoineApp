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
    return RealEstateAsset(
      id: json['id'],
      categoryId: json['category_id'],
      categoryName:
          json['real_estate_category']['label'] ??
          json['real_estate_category']['name'],
      label: json['label'],
      amount: (json['amount'] as num).toDouble(),
      address: json['address'],
    );
  }
}
