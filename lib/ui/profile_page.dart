import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'tools/real_estate_simulator_page.dart';

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
    const Color colorBlue = Color(0xFF0D71EE);
    const Color colorSurface = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: const Color(0xFF060B26),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // --- ENTÊTE MENU ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorSurface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colorBlue.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, size: 32, color: colorBlue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "MON COMPTE",
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          Supabase.instance.client.auth.currentUser?.email ??
                              "Utilisateur",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- SECTION OUTILS ---
            _buildToolSection(context, colorBlue),

            const SizedBox(height: 24),

            // --- AUTRES OPTIONS ---
            _buildMenuOption(
              icon: Icons.info_outline,
              title: "À propos",
              subtitle: "Version de l'application",
              trailing: Text(
                widget.appVersion,
                style: const TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ),

            const SizedBox(height: 40),

            // --- BOUTON DÉCONNEXION ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorRed.withValues(alpha: 0.1),
                  foregroundColor: colorRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: colorRed.withValues(alpha: 0.3)),
                ),
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text(
                  "DÉCONNEXION",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        trailing:
            trailing ?? const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: onTap,
      ),
    );
  }

  Widget _buildToolSection(BuildContext context, Color colorBlue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "OUTILS & SIMULATEURS",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        _buildMenuOption(
          icon: Icons.home_work,
          title: "Simulateur Immobilier",
          subtitle: "Calculez votre capacité d'achat",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RealEstateSimulatorPage(),
              ),
            );
          },
        ),
      ],
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
