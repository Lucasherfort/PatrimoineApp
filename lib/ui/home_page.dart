import 'package:flutter/material.dart';
import '../services/patrimoine_service.dart';
import '../services/theme_manager.dart';
import '../widgets/Investment/investment_list.dart';
import '../widgets/Savings/savings_account_list.dart';
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
  final PatrimoineService _patrimoineService = PatrimoineService();

  // Couleurs cohérentes avec le reste de l'app
  static const Color colorBlueMain = Color(0xFF0D71EE);

  double patrimoineTotal = 0.0;
  double investedCapital = 0.0;
  double portfolioValue = 0.0;
  double netPatrimoine = 0.0;
  bool isLoading = true;

  bool hasLiquidityAccounts = false;
  bool hasSavingsAccounts = false;
  bool hasInvestmentAccounts = false;

  @override
  void initState() {
    super.initState();
    _loadPatrimoine();
    ThemeManager().addListener(_loadPatrimoine);
  }

  @override
  void dispose() {
    ThemeManager().removeListener(_loadPatrimoine);
    super.dispose();
  }

  Future<void> openAddPatrimoinePanel() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddPatrimoineWizard(),
    );

    if (result == true) {
      _loadPatrimoine();
    }
  }

  Future<void> _loadPatrimoine() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final total = await _patrimoineService.getPatrimoine();
      final liquidity = await _patrimoineService.hasLiquidityAccounts();
      final savings = await _patrimoineService.hasSavingsAccounts();
      final investments = await _patrimoineService.hasInvestmentAccounts();
      final investedCapitalAmount = await _patrimoineService
          .getTotalInvestedCapital();
      final portfolioValueAmount = await _patrimoineService
          .getTotalPortfolioValue();
      final netPatrimoineAmount = await _patrimoineService.getNetPatrimoine();

      if (mounted) {
        setState(() {
          patrimoineTotal = total;
          hasLiquidityAccounts = liquidity;
          hasSavingsAccounts = savings;
          hasInvestmentAccounts = investments;
          investedCapital = investedCapitalAmount;
          netPatrimoine = netPatrimoineAmount;
          portfolioValue = portfolioValueAmount;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? Colors.white : colorBlueMain,
          ),
        ),
      );
    }

    final hasAnyAccount =
        hasLiquidityAccounts || hasSavingsAccounts || hasInvestmentAccounts;

    return Scaffold(
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF8FAFC),
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
                color: colorBlueMain.withValues(alpha: isDark ? 0.12 : 0.08),
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
                color: colorBlueMain.withValues(alpha: isDark ? 0.08 : 0.05),
              ),
            ),
          ),

          // --- CONTENU PRINCIPAL ---
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                PatrimoineHeader(
                  patrimoineTotal: patrimoineTotal,
                  investedCapital: investedCapital,
                  portfolioValue: portfolioValue,
                  netWorth: investedCapital,
                  netPatrimoine: netPatrimoine,
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
                            ],
                          ),
                        )
                      : _buildEmptyState(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 60,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            "Aucun compte disponible",
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : const Color(0xFF0F172A).withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Utilisez le bouton + pour commencer",
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.3),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
