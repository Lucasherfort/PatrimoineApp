import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/patrimoine_service.dart';
import '../widgets/Investment/investment_list.dart';
import '../widgets/Savings/savings_account_list.dart';
import '../widgets/advantage/advantage_account_list.dart';
import '../widgets/patrimoine/add_patrimoine_wizard.dart';
import '../widgets/Liquidity/liquidity_account_list.dart';
import '../widgets/patrimoine/patrimoine_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PatrimoineService _service = PatrimoineService();

  double patrimoineTotal = 0.0;
  bool isLoading = true;
  String appVersion = ''; // 👈 Nouvelle variable

  bool hasLiquidityAccounts = false;
  bool hasSavingsAccounts = false;
  bool hasInvestmentAccounts = false;
  bool hasAdvantageAccounts = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Charger la version en premier
    await _loadAppVersion();
    // Puis charger le reste
    await _loadPatrimoine();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = 'v${packageInfo.version}';
    });
  }

  Future<void> _loadPatrimoine() async {
    setState(() => isLoading = true);

    try {
      final total = await _service.getPatrimoine();

      final liquidity = await _service.hasLiquidityAccounts();
      final savings = await _service.hasSavingsAccounts();
      final investments = await _service.hasInvestmentAccounts();
      final advantages = await _service.hasAdvantageAccounts();

      setState(() {
        patrimoineTotal = total;
        hasLiquidityAccounts = liquidity;
        hasSavingsAccounts = savings;
        hasInvestmentAccounts = investments;
        hasAdvantageAccounts = advantages;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement patrimoine: $e')),
        );
      }
    }
  }

  Future<void> _refreshAll() async {
    await _loadPatrimoine();
  }

  void _openAddPatrimoinePanel() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddPatrimoineWizard(),
    );

    if (result == true) {
      await _refreshAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasAnyAccount = hasLiquidityAccounts ||
        hasSavingsAccounts ||
        hasInvestmentAccounts ||
        hasAdvantageAccounts;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text("Patrimoine App"),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                appVersion,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPatrimoinePanel,
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          PatrimoineHeader(
            patrimoineTotal: patrimoineTotal,
            onRefresh: _refreshAll,
          ),

          Expanded(
            child: hasAnyAccount
                ? ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                if (hasLiquidityAccounts)
                  LiquidityAccountList(
                    onAccountUpdated: _refreshAll,
                  ),
                if (hasSavingsAccounts)
                  SavingsAccountList(
                    onAccountUpdated: _refreshAll,
                  ),
                if (hasInvestmentAccounts)
                  InvestmentList(
                    onAccountUpdated: _refreshAll,
                  ),
                if (hasAdvantageAccounts)
                  AdvantageAccountList(
                    onAccountUpdated: _refreshAll,
                  ),
              ],
            )
                : const Center(
              child: Text(
                "Aucun compte disponible",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}