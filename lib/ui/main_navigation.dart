import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'graphs_page.dart'; // <--- Assure-toi que l'import est correct

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  String appVersion = '';
  String appName = 'Patrimoine 360';

  // La clé pour piloter la HomePage (Patrimoine)
  final GlobalKey<HomePageState> _homeKey = GlobalKey<HomePageState>();

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          appName = packageInfo.appName;
          appVersion = 'v${packageInfo.version}';
        });
      }
    } catch (e) {
      debugPrint('Erreur infos app: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Définition des titres (on garde les textes simples pour le reste de la logique)
    final List<String> titles = [
      "Patrimoine",
      "Analyses",
      "Mes Dépenses",
      "Mon Profil"
    ];

    final List<Widget> pages = [
      HomePage(key: _homeKey, appName: appName, appVersion: appVersion),
      const GraphsPage(appName: '', appVersion: '',),
      _buildExpenseSection(),
      _buildProfileSection(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        // MODIFICATION ICI : On utilise une Row pour le titre
        title: Row(
          children: [
            if (_currentIndex == 0) ...[
              const Icon(
                Icons.account_balance, // Le même logo que la barre du bas
                color: Colors.blueAccent,
                size: 24,
              ),
              const SizedBox(width: 10), // Espace entre l'icône et le texte
            ],
            Text(
              titles[_currentIndex],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 28),
              onPressed: () => _homeKey.currentState?.openAddPatrimoinePanel(),
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.white.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Patrimoine'),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Graphiques'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Dépenses'),
          BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildExpenseSection() {
    return const Center(
      child: Text("Gestion des dépenses à venir", style: TextStyle(color: Colors.white54)),
    );
  }

  Widget _buildProfileSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            Supabase.instance.client.auth.currentUser?.email ?? "Utilisateur",
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
            label: const Text("Déconnexion"),
          ),
          const SizedBox(height: 20),
          Text(appVersion, style: const TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }
}