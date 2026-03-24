class UserAdvantageAccountView {
  final int id;
  final String sourceName;
  final String providerName;
  final String logoUrl; // 👈 Nouveau champ
  final double value;

  UserAdvantageAccountView({
    required this.id,
    required this.sourceName,
    required this.providerName,
    required this.logoUrl, // 👈 Ajouté
    required this.value,
  });
}
