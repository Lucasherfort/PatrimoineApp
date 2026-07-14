import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'ui/main_navigation.dart';
import 'ui/login_page.dart';
import 'services/theme_manager.dart';

void main() async {
  // 1. Indispensable pour les appels asynchrones au démarrage
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialisation des données de localisation
  await initializeDateFormatting('fr_FR', null);
  Intl.defaultLocale = 'fr_FR';

  // 3. Initialisation Supabase
  await Supabase.initialize(
    url: 'https://hkwrmzubtmdoolleqnyt.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhrd3JtenVidG1kb29sbGVxbnl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgwNTk3NTIsImV4cCI6MjA4MzYzNTc1Mn0.5h6Fcn5MmrEun3OutmI12M8_gk8LFr5WeZomK-fl9FA',
  );

  // 4. Initialisation du Theme
  await ThemeManager().init();

  // 5. Blocage de l'orientation en mode portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const PatrimoineApp());
}

class PatrimoineApp extends StatelessWidget {
  const PatrimoineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, child) {
        return MaterialApp(
          title: 'Patrimoine App',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeManager().themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('fr', 'FR')],
          locale: const Locale('fr', 'FR'),
          // Thème Clair
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D71EE),
              brightness: Brightness.light,
              surface: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            cardColor: Colors.white,
            useMaterial3: true,
          ),
          // Thème Sombre
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D71EE),
              brightness: Brightness.dark,
              surface: const Color(0xFF1E293B),
            ),
            scaffoldBackgroundColor: const Color(0xFF060B26),
            cardColor: const Color(0xFF1E293B),
            useMaterial3: true,
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // On utilise un StreamBuilder pour écouter les changements d'état (connexion/déconnexion)
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Pendant que Supabase initialise l'état initial du stream
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF0D71EE)),
            ),
          );
        }

        // On vérifie si une session est active
        final session = Supabase.instance.client.auth.currentSession;

        if (session != null) {
          return const MainNavigation();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
