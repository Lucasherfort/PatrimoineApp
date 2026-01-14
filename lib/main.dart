import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ui/home_page.dart';
import 'ui/login_page.dart';

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

      /// 🔐 Redirection automatique selon l'état d'auth
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session;

          if (session == null)
          {
            return const LoginPage();
          }

          return const HomePage();
        },
      ),
    );
  }
}