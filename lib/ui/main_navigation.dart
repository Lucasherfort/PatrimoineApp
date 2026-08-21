import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/app_localizations.dart';
import 'home_page.dart';
import 'analysis_page.dart';
import 'budget_page.dart';
import 'simulators_page.dart';
import 'profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  String appVersion = '';
  String appName = 'Patrimoine 360';

  // Couleur officielle
  static const Color colorBlueMain = Color(0xFF0D71EE);

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
      debugPrint('Erreur infos app : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> pages = [
      HomePage(key: _homeKey, appName: appName, appVersion: appVersion),

      const AnalysisPage(),

      const BudgetPage(),

      const SimulatorsPage(),

      ProfilePage(appVersion: appVersion),
    ];

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: theme.cardColor,
        selectedItemColor: colorBlueMain,
        unselectedItemColor: isDark
            ? Colors.white.withValues(alpha: 0.4)
            : Colors.black26,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.business_center),
            label: l10n.navHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: l10n.navAnalysis,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.pie_chart_rounded),
            label: l10n.navBudget,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.rocket_launch_rounded),
            label: l10n.navSimulators,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
