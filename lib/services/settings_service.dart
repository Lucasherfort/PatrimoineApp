class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // On pourra ajouter d'autres réglages ici si besoin
}
