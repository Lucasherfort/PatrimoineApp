// lib/services/app_version_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/config/app_version_config.dart';

class AppVersionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static final AppVersionService _instance = AppVersionService._internal();
  factory AppVersionService() => _instance;
  AppVersionService._internal();

  /// Récupère la configuration de version depuis Supabase
  Future<AppVersionConfig> getVersionConfig() async {
    try {
      final response = await _supabase
          .from('app_version')
          .select()
          .single();

      return AppVersionConfig.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Vérifie le statut de l'application
  /// Retourne:
  /// - 'ok' : Tout va bien
  /// - 'maintenance' : Mode maintenance activé
  /// - 'update_required' : Mise à jour obligatoire
  /// - 'update_available' : Mise à jour disponible (optionnelle)
  Future<AppStatus> checkAppStatus(String currentAppVersion) async {
    try {
      final config = await getVersionConfig();

      // Mode maintenance
      if (config.isMaintenance) {
        return AppStatus(
          status: AppStatusType.maintenance,
          message: config.maintenanceMessage ??
              'L\'application est en maintenance. Veuillez réessayer plus tard.',
        );
      }

      // Mise à jour obligatoire
      if (config.isUpdateRequired(currentAppVersion)) {
        return AppStatus(
          status: AppStatusType.updateRequired,
          message: config.updateMessage ??
              'Une mise à jour obligatoire est disponible. Veuillez mettre à jour l\'application.',
          latestVersion: config.currentVersion,
        );
      }

      // Mise à jour disponible (optionnelle)
      if (config.hasUpdateAvailable(currentAppVersion)) {
        return AppStatus(
          status: AppStatusType.updateAvailable,
          message: config.updateMessage ??
              'Une nouvelle version est disponible.',
          latestVersion: config.currentVersion,
        );
      }

      // Tout va bien
      return AppStatus(status: AppStatusType.ok);
    } catch (e) {
      // En cas d'erreur, laisser passer l'utilisateur
      return AppStatus(status: AppStatusType.ok);
    }
  }
}

enum AppStatusType {
  ok,
  maintenance,
  updateRequired,
  updateAvailable,
}

class AppStatus {
  final AppStatusType status;
  final String? message;
  final String? latestVersion;

  AppStatus({
    required this.status,
    this.message,
    this.latestVersion,
  });
}