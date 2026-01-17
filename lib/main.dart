import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  runApp(const PatrimoineApp());
}

class PatrimoineApp extends StatelessWidget {
  const PatrimoineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patrimoine App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
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
  String? _currentVersion;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _currentVersion = info.version;

      final status = await _versionService.checkAppStatus(info.version);

      if (mounted) setState(() => _appStatus = status);
    } catch (e) {
      if (mounted) setState(() => _appStatus = AppStatus(status: AppStatusType.ok));
    }
  }

  void _handleRetry() => _checkVersion();

  @override
  Widget build(BuildContext context) {
    // Bloquer si maintenance ou update obligatoire
    if (_appStatus?.status == AppStatusType.maintenance ||
        _appStatus?.status == AppStatusType.updateRequired) {
      return AppBlockedPage(appStatus: _appStatus!, onRetry: _handleRetry);
    }

    // 👇 CHANGÉ : Utiliser initialData au lieu de _initialSession
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        Supabase.instance.client.auth.currentSession,
      ), // 👈 Fournir la session initiale
      builder: (context, snapshot) {
        // 👇 CHANGÉ : Récupérer la session depuis snapshot.data
        final session = snapshot.hasData ? snapshot.data!.session : null;

        // Notification si update disponible
        if (_appStatus?.status == AppStatusType.updateAvailable) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showUpdateAvailableDialog(context);
          });
        }

        // Affiche directement HomePage si session existante, sinon LoginPage
        if (session == null) {
          return const LoginPage();
        } else {
          return const HomePage();
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
        title: const Text('Mise à jour disponible'),
        content: Text(_appStatus?.message ?? 'Une nouvelle version est disponible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

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