import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:patrimoine360/ui/profile_page.dart';
import 'budget_page.dart';
import 'home_page.dart';
import 'graphs_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  String appVersion = '';
  String appName = 'Patrimoine 360';

  // Tes couleurs officielles
  static const Color colorBlueMain = Color(0xFF0D71EE);
  static const Color colorDarkBg = Color(0xFF060B26);
  static const Color colorSurface = Color(0xFF1E293B);

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
    // Liste des textes d'onglets
    final List<String> titles = [
      "Patrimoine",
      "Analyses",
      "Mon Budget",
      "Plus",
    ];

    // Liste des icônes correspondantes pour l'AppBar
    final List<IconData> titleIcons = [
      Icons.account_balance,
      Icons.insights,
      Icons.receipt_long,
      Icons.menu,
    ];

    final List<Widget> pages = [
      HomePage(key: _homeKey, appName: appName, appVersion: appVersion),
      const GraphsPage(appName: '', appVersion: ''),
      const BudgetPage(),
      ProfilePage(appVersion: appVersion),
    ];

    return Scaffold(
      backgroundColor: colorDarkBg,
      appBar: AppBar(
        backgroundColor: colorSurface,
        elevation: 0,
        titleSpacing: 20, // Un peu plus d'air à gauche
        title: Row(
          children: [
            // Le logo dynamique à gauche
            Icon(titleIcons[_currentIndex], color: colorBlueMain, size: 24),
            const SizedBox(width: 12),
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
              icon: const Icon(
                Icons.add_circle,
                color: colorBlueMain,
                size: 28,
              ),
              onPressed: () => _homeKey.currentState?.openAddPatrimoinePanel(),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: colorDarkBg,
        selectedItemColor: colorBlueMain,
        unselectedItemColor: Colors.white.withValues(alpha: 0.4),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Patrimoine',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Graphiques',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Budget',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Plus'),
        ],
      ),
    );
  }
}
