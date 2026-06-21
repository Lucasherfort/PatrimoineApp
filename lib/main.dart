import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/date_symbol_data_local.dart'; // 👈 AJOUTÉ
import 'package:intl/intl.dart'; // 👈 AJOUTÉ

import 'ui/main_navigation.dart';
import 'ui/login_page.dart';
import 'ui/app_blocked_page.dart';
import 'services/app_version_service.dart';

void main() async {
  // 1. Indispensable pour les appels asynchrones au démarrage
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialisation des données de localisation (Correction erreur LocaleDataException)
  await initializeDateFormatting('fr_FR', null);
  Intl.defaultLocale = 'fr_FR';

  // 3. Initialisation Supabase
  await Supabase.initialize(
    url: 'https://hkwrmzubtmdoolleqnyt.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhrd3JtenVidG1kb29sbGVxbnl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgwNTk3NTIsImV4cCI6MjA4MzYzNTc1Mn0.5h6Fcn5MmrEun3OutmI12M8_gk8LFr5WeZomK-fl9FA',
  );

  runApp(const PatrimoineApp());
}

class PatrimoineApp extends StatelessWidget {
  const PatrimoineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patrimoine App',
      debugShowCheckedModeBanner: false,
      // Thème global sombre pour cohérence avec ton design
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF060B26),
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
  AppStatus? _appStatus;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final status = await _versionService.checkAppStatus(info.version);

      if (mounted) {
        setState(() => _appStatus = status);
      }
    } catch (e) {
      // En cas d'erreur réseau, on laisse passer par défaut
      if (mounted) {
        setState(() => _appStatus = AppStatus(status: AppStatusType.ok));
      }
    }
  }

  void _handleRetry() => _checkVersion();

  @override
  Widget build(BuildContext context) {
    // 1. Écran de chargement tant que le statut n'est pas récupéré
    if (_appStatus == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0D71EE)),
        ),
      );
    }

    // 2. Bloquer si maintenance ou mise à jour obligatoire
    if (_appStatus?.status == AppStatusType.maintenance ||
        _appStatus?.status == AppStatusType.updateRequired) {
      return AppBlockedPage(appStatus: _appStatus!, onRetry: _handleRetry);
    }

    // 3. Gestion de l'authentification si l'app est OK
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.hasData ? snapshot.data!.session : null;

        // Notification si mise à jour facultative disponible (Post Frame pour éviter build error)
        if (_appStatus?.status == AppStatusType.updateAvailable) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showUpdateAvailableDialog(context);
          });
        }

        if (session == null) {
          return const LoginPage();
        } else {
          return const MainNavigation();
        }
      },
    );
  }

  void _showUpdateAvailableDialog(BuildContext context) {
    if (_appStatus == null) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Mise à jour disponible'),
        content: Text(
          _appStatus?.message ?? 'Une nouvelle version est disponible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Plus tard',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D71EE),
            ),
            onPressed: () async {
              Navigator.pop(context);

              if (_appStatus?.apkUrl != null) {
                final Uri url = Uri.parse(_appStatus!.apkUrl!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: const Text(
              'Mettre à jour',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
