import 'package:flutter/material.dart';
import '../services/patrimoine_service.dart';
import '../widgets/Investment/investment_list.dart';
import '../widgets/Savings/savings_account_list.dart';
import '../widgets/advantage/advantage_account_list.dart';
import '../widgets/patrimoine/add_patrimoine_wizard.dart';
import '../widgets/Liquidity/liquidity_account_list.dart';
import '../widgets/patrimoine/patrimoine_header.dart';

class HomePage extends StatefulWidget {
  final String appName;
  final String appVersion;

  const HomePage({super.key, required this.appName, required this.appVersion});

  @override
  State<HomePage> createState() => HomePageState(); // Nom public sans "_"
}

class HomePageState extends State<HomePage> {
  final PatrimoineService _service = PatrimoineService();

  double patrimoineTotal = 0.0;
  double totalDepose = 0.0;
  double capitalOwned = 0.0;
  double patrimoineOwned = 0.0;
  bool isLoading = true;

  bool hasLiquidityAccounts = false;
  bool hasSavingsAccounts = false;
  bool hasInvestmentAccounts = false;
  bool hasAdvantageAccounts = false;

  @override
  void initState() {
    super.initState();
    _loadPatrimoine();
  }

  // APPELÉ DEPUIS MAIN_NAVIGATION
  Future<void> openAddPatrimoinePanel() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const AddPatrimoineWizard(),
      ),
    );

    if (result == true) {
      _loadPatrimoine();
    }
  }

  Future<void> _loadPatrimoine() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final total = await _service.getPatrimoine();
      final deposedAmount = await _service.getTotalDeposed();
      final capitalOwnedAmount = await _service.getTotalOwnedCapital();
      final patrimoineOwnedAmount = await _service.getPatrimoineOwned();
      final liquidity = await _service.hasLiquidityAccounts();
      final savings = await _service.hasSavingsAccounts();
      final investments = await _service.hasInvestmentAccounts();
      final advantages = await _service.hasAdvantageAccounts();

      if (mounted) {
        setState(() {
          patrimoineTotal = total;
          totalDepose = deposedAmount;
          capitalOwned = capitalOwnedAmount;
          patrimoineOwned = patrimoineOwnedAmount;
          hasLiquidityAccounts = liquidity;
          hasSavingsAccounts = savings;
          hasInvestmentAccounts = investments;
          hasAdvantageAccounts = advantages;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final hasAnyAccount = hasLiquidityAccounts ||
        hasSavingsAccounts ||
        hasInvestmentAccounts ||
        hasAdvantageAccounts;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A), Colors.black],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            PatrimoineHeader(
              patrimoineTotal: patrimoineTotal,
              totalDepose: totalDepose,
              capitalOwned: capitalOwned,
              patrimoineOwned: patrimoineOwned,
              onRefresh: _loadPatrimoine,
            ),
            Expanded(
              child: hasAnyAccount
                  ? RefreshIndicator(
                onRefresh: _loadPatrimoine,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    if (hasLiquidityAccounts) LiquidityAccountList(onAccountUpdated: _loadPatrimoine),
                    if (hasSavingsAccounts) SavingsAccountList(onAccountUpdated: _loadPatrimoine),
                    if (hasInvestmentAccounts) InvestmentList(onAccountUpdated: _loadPatrimoine),
                    if (hasAdvantageAccounts) AdvantageAccountList(onAccountUpdated: _loadPatrimoine),
                  ],
                ),
              )
                  : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 60, color: Colors.white24),
          const SizedBox(height: 16),
          const Text("Aucun compte disponible", style: TextStyle(color: Colors.white70)),
          const Text("Utilisez le bouton + pour en ajouter", style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }
}