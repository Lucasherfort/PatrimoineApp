// lib/models/config/app_version_config.dart
class AppVersionConfig {
  final String currentVersion; // dernière version dispo
  final String minVersion;     // version minimale autorisée
  final bool isMaintenance;
  final String? updateMessage;
  final String? maintenanceMessage;
  final String? apkUrl;

  AppVersionConfig({
    required this.currentVersion,
    required this.minVersion,
    required this.isMaintenance,
    this.updateMessage,
    this.maintenanceMessage,
    this.apkUrl,
  });

  factory AppVersionConfig.fromMap(Map<String, dynamic> map) {
    return AppVersionConfig(
      currentVersion: map['current_version'],
      minVersion: map['min_version'],
      isMaintenance: map['maintenance'] ?? false,
      updateMessage: map['update_message'],
      maintenanceMessage: map['maintenance_message'],
      apkUrl: map['apk_url'],
    );
  }

  /// ❌ current < minVersion
  bool isUpdateRequired(String currentAppVersion) {
    return _compareVersions(currentAppVersion, minVersion) < 0;
  }

  /// ⚠️ current < currentVersion
  bool hasUpdateAvailable(String currentAppVersion) {
    return _compareVersions(currentAppVersion, currentVersion) < 0;
  }

  /// 🔢 Comparaison semver sécurisée
  int _compareVersions(String v1, String v2) {
    final v1Parts = v1.split('.').map(int.parse).toList();
    final v2Parts = v2.split('.').map(int.parse).toList();

    final maxLength = v1Parts.length > v2Parts.length
        ? v1Parts.length
        : v2Parts.length;

    for (int i = 0; i < maxLength; i++) {
      final p1 = i < v1Parts.length ? v1Parts[i] : 0;
      final p2 = i < v2Parts.length ? v2Parts[i] : 0;

      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }
}
