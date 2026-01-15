// lib/models/app_version_config.dart

class AppVersionConfig {
  final String currentVersion;
  final String minimumVersion;
  final bool isMaintenance;
  final String? maintenanceMessage;
  final String? updateMessage;

  AppVersionConfig({
    required this.currentVersion,
    required this.minimumVersion,
    required this.isMaintenance,
    this.maintenanceMessage,
    this.updateMessage,
  });

  factory AppVersionConfig.fromMap(Map<String, dynamic> map) {
    return AppVersionConfig(
      currentVersion: map['current_version'] as String,
      minimumVersion: map['minimum_version'] as String,
      isMaintenance: map['is_maintenance'] as bool? ?? false,
      maintenanceMessage: map['maintenance_message'] as String?,
      updateMessage: map['update_message'] as String?,
    );
  }

  /// Compare deux versions (format: "1.2.3")
  static int compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;

      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  /// Vérifie si une mise à jour est disponible
  bool hasUpdateAvailable(String currentAppVersion) {
    return compareVersions(currentVersion, currentAppVersion) > 0;
  }

  /// Vérifie si la mise à jour est obligatoire
  bool isUpdateRequired(String currentAppVersion) {
    return compareVersions(currentAppVersion, minimumVersion) < 0;
  }
}