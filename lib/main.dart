import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ui/home_page.dart';
import 'ui/login_page.dart';
import 'ui/app_blocked_page.dart';
import 'services/app_version_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hkwrmzubtmdoolleqnyt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhrd3JtenVidG1kb29sbGVxbnl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgwNTk3NTIsImV4cCI6MjA4MzYzNTc1Mn0.5h6Fcn5MmrEun3OutmI12M8_gk8LFr5WeZomK-fl9FA',
  );

  // Vérifier si la session est toujours valide
  final session = Supabase.instance.client.auth.currentSession;
  if (session != null) {
    try {
      // Tenter de récupérer l'utilisateur pour vérifier s'il existe encore
      await Supabase.instance.client.auth.getUser();
    } catch (e) {
      // Si erreur (compte supprimé), déconnecter
      await Supabase.instance.client.auth.signOut();
    }
  }

  runApp(const PatrimoineApp());
}

class PatrimoineApp extends StatelessWidget {
  const PatrimoineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patrimoine App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AppVersionChecker(),
    );
  }
}

class AppVersionChecker extends StatefulWidget {
  const AppVersionChecker({super.key});

  @override
  State<AppVersionChecker> createState() => _AppVersionCheckerState();
}

class _AppVersionCheckerState extends State<AppVersionChecker> {
  final AppVersionService _versionService = AppVersionService();
  bool _isChecking = true;
  AppStatus? _appStatus;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      // Récupérer la version de l'app
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Vérifier le statut
      final status = await _versionService.checkAppStatus(currentVersion);

      if (mounted) {
        setState(() {
          _appStatus = status;
          _isChecking = false;
        });
      }
    } catch (e) {
      // En cas d'erreur, laisser passer
      if (mounted) {
        setState(() {
          _appStatus = AppStatus(status: AppStatusType.ok);
          _isChecking = false;
        });
      }
    }
  }

  void _handleRetry() {
    setState(() {
      _isChecking = true;
    });
    _checkVersion();
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Bloquer l'accès si maintenance ou mise à jour obligatoire
    if (_appStatus?.status == AppStatusType.maintenance ||
        _appStatus?.status == AppStatusType.updateRequired) {
      return AppBlockedPage(
        appStatus: _appStatus!,
        onRetry: _handleRetry,
      );
    }

    // Afficher l'app normalement
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        // Afficher une notification si mise à jour disponible (optionnelle)
        if (_appStatus?.status == AppStatusType.updateAvailable) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showUpdateAvailableDialog(context);
            }
          });
        }

        if (session == null) {
          return const LoginPage();
        }

        return const HomePage();
      },
    );
  }

  void _showUpdateAvailableDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Mise à jour disponible'),
        content: Text(
          _appStatus?.message ?? 'Une nouvelle version est disponible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Ouvrir le lien de téléchargement si disponible
              if (_appStatus?.apkUrl != null) {
                final Uri url = Uri.parse(_appStatus!.apkUrl!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }
}