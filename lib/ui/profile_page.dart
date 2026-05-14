import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/settings_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final String appVersion;
  const ProfilePage({super.key, required this.appVersion});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SettingsService _settingsService = SettingsService();
  final TextEditingController _targetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    double target = await _settingsService.getTargetBalance();
    setState(() {
      _targetController.text = target.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color colorBlueMain = Color(0xFF0D71EE);
    const Color colorRed = Color(0xFFFC5555);

    return Scaffold(
      backgroundColor: const Color(0xFF060B26),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.person_pin, size: 80, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              Supabase.instance.client.auth.currentUser?.email ?? "Utilisateur",
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // --- SECTION PARAMÈTRES ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune, color: colorBlueMain, size: 20),
                      SizedBox(width: 10),
                      Text("Paramètres Budget", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          "Seuil de confort compte courant",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _targetController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: colorBlueMain, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            suffixText: "€",
                            suffixStyle: const TextStyle(color: Colors.white24),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                          ),
                          onSubmitted: (val) async {
                            final d = double.tryParse(val);
                            if (d != null) await _settingsService.setTargetBalance(d);
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seuil mis à jour !")));
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- BOUTON DÉCONNEXION ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorRed.withOpacity(0.1),
                  foregroundColor: colorRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: colorRed.withOpacity(0.3)),
                ),
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text("DÉCONNEXION", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            Text(widget.appVersion, style: const TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }
}