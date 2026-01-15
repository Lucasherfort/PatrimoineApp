// lib/ui/app_blocked_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_version_service.dart';

class AppBlockedPage extends StatelessWidget {
  final AppStatus appStatus;
  final VoidCallback? onRetry;

  const AppBlockedPage({
    super.key,
    required this.appStatus,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: appStatus.status == AppStatusType.maintenance
                ? [Colors.orange.shade400, Colors.orange.shade700]
                : [Colors.red.shade400, Colors.red.shade700],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône
                  Icon(
                    appStatus.status == AppStatusType.maintenance
                        ? Icons.construction
                        : Icons.system_update,
                    size: 100,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 32),

                  // Titre
                  Text(
                    _getTitle(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Message
                  Text(
                    appStatus.message ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Version si disponible
                  if (appStatus.latestVersion != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Version disponible: ${appStatus.latestVersion}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // Bouton d'action
                  if (appStatus.status == AppStatusType.updateRequired)
                    ElevatedButton.icon(
                      onPressed: _openApkDownload, // 👈 Changé ici
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.download),
                      label: const Text(
                        'Mettre à jour',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  if (appStatus.status == AppStatusType.maintenance)
                    ElevatedButton(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.orange.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Réessayer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (appStatus.status) {
      case AppStatusType.maintenance:
        return 'Maintenance en cours';
      case AppStatusType.updateRequired:
        return 'Mise à jour requise';
      default:
        return 'Action requise';
    }
  }

  // 👇 Nouvelle méthode qui utilise apkUrl
  Future<void> _openApkDownload() async {
    final url = Uri.parse(appStatus.apkUrl!);
    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }
}