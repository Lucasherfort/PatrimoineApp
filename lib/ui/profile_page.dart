import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final String appVersion;
  const ProfilePage({super.key, required this.appVersion});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    const Color colorRed = Color(0xFFFC5555);

    return Scaffold(
      backgroundColor: const Color(0xFF060B26),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.person_pin, size: 80, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              Supabase.instance.client.auth.currentUser?.email ?? "Utilisateur",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 60),

            // --- BOUTON DÉCONNEXION ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorRed.withValues(alpha: 0.1),
                  foregroundColor: colorRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: colorRed.withValues(alpha: 0.3)),
                ),
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text("DÉCONNEXION", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
                widget.appVersion,
                style: const TextStyle(color: Colors.white24, fontSize: 12)
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // 1. On capture le Navigator avant le await
    final navigator = Navigator.of(context);

    await Supabase.instance.client.auth.signOut();

    // 2. On vérifie le mounted du BuildContext (disponible depuis Flutter 3.7+)
    if (!context.mounted) return;

    // 3. On utilise l'instance du navigator capturée
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }
}