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
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final PatrimoineService _service = PatrimoineService();

  // Couleurs cohérentes avec le reste de l'app
  static const Color colorDarkBg = Color(0xFF060B26);
  static const Color colorBlueMain = Color(0xFF0D71EE);

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur chargement: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: colorDarkBg,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final hasAnyAccount =
        hasLiquidityAccounts ||
        hasSavingsAccounts ||
        hasInvestmentAccounts ||
        hasAdvantageAccounts;

    return Scaffold(
      backgroundColor: colorDarkBg, // Couleur de base
      body: Stack(
        children: [
          // --- EFFET DE FOND (Halos) ---
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorBlueMain.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorBlueMain.withValues(alpha: 0.08),
              ),
            ),
          ),

          // --- CONTENU PRINCIPAL ---
          SafeArea(
            child: Column(
              children: [
                PatrimoineHeader(
                  patrimoineTotal: patrimoineTotal,
                  totalDepose: totalDepose,
                  capitalOwned: capitalOwned,
                  patrimoineOwned: patrimoineOwned,
                ),
                Expanded(
                  child: hasAnyAccount
                      ? RefreshIndicator(
                          onRefresh: _loadPatrimoine,
                          color: Colors.white,
                          backgroundColor: colorBlueMain,
                          child: ListView(
                            padding: const EdgeInsets.only(
                              bottom: 100,
                            ), // Espace pour la barre de navigation
                            children: [
                              if (hasLiquidityAccounts)
                                LiquidityAccountList(
                                  onAccountUpdated: _loadPatrimoine,
                                ),
                              if (hasSavingsAccounts)
                                SavingsAccountList(
                                  onAccountUpdated: _loadPatrimoine,
                                ),
                              if (hasInvestmentAccounts)
                                InvestmentList(
                                  onAccountUpdated: _loadPatrimoine,
                                ),
                              if (hasAdvantageAccounts)
                                AdvantageAccountList(
                                  onAccountUpdated: _loadPatrimoine,
                                ),
                            ],
                          ),
                        )
                      : _buildEmptyState(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 60,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            "Aucun compte disponible",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Utilisez le bouton + pour commencer",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
