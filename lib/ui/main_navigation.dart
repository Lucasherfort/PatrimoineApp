import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
      debugPrint('Erreur récupération infos application: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Les deux pages (onglets)
    final pages = [
      HomePage(
        appName: appName,
        appVersion: appVersion,
      ), // Onglet "Comptes"
      GraphsPage(
        appName: appName,
        appVersion: appVersion,
      ), // Onglet "Graphiques"
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Comptes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Graphiques',
          ),
        ],
      ),
    );
  }
}