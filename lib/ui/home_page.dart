import 'package:flutter/material.dart';
import '../services/patrimoine_service.dart';
import '../widgets/add_patrimoine_wizard.dart';
import '../widgets/liquidity_account_list.dart';
import '../widgets/patrimoine_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PatrimoineService _service = PatrimoineService();

  double patrimoineTotal = 0.0;
  bool isLoading = true;

  bool hasLiquidityAccounts = false;
  bool hasSavingsAccounts = false;
  bool hasInvestmentAccounts = false;
  bool hasVouchers = false;

  @override
  void initState() {
    super.initState();
    _loadPatrimoine();
  }

  Future<void> _loadPatrimoine() async {
    setState(() => isLoading = true);

    try {
      final total = await _service.getPatrimoine();

      final liquidity = await _service.hasLiquidityAccounts();
      final savings = await _service.hasSavingsAccounts();

      setState(() {
        patrimoineTotal = total;
        hasLiquidityAccounts = liquidity;
        hasSavingsAccounts = savings;
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
        hasVouchers;

    return Scaffold(
      appBar: AppBar(title: const Text("Patrimoine App")),

      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPatrimoinePanel,
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          // ✅ HEADER
          PatrimoineHeader(
            patrimoineTotal: patrimoineTotal,
            onRefresh: _refreshAll,
          ),

          // ✅ LISTES
          Expanded(
            child: hasAnyAccount
                ? ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                if (hasLiquidityAccounts)
                  LiquidityAccountList(
                    onAccountUpdated: _refreshAll,
                  ),
/*
                if (hasSavingsAccounts)
                  SavingsAccountList(
                    onAccountUpdated: _refreshAll,
                  ),

 */


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