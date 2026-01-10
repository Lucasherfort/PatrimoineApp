import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/patrimoine_service.dart';
import '../widgets/add_patrimoine_wizard.dart';
import '../widgets/patrimoine_header.dart';
import '../widgets/cash_account_list.dart';
import '../widgets/savings_account_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double patrimoineTotal = 0.0;
  bool isLoading = true;

  bool hasCashAccounts = false;
  bool hasSavingsAccounts = false;
  bool hasInvestmentAccounts = false;
  bool hasVouchers = false;

  late final PatrimoineService patrimoineService;

  @override
  void initState() {
    super.initState();
    patrimoineService = PatrimoineService(Supabase.instance.client);
    _loadPatrimoine();
  }

  Future<void> _loadPatrimoine() async {
    setState(() => isLoading = true);

    // 🔹 Total cash via Supabase RPC
    final totalCash = await patrimoineService.getPatrimoine();

    // 🔹 Pour l'instant, on suppose que les autres comptes sont absents
    final totalOther = 0.0;

    setState(() {
      patrimoineTotal = totalCash + totalOther;
      hasCashAccounts = totalCash > 0;
      hasSavingsAccounts = false;
      hasInvestmentAccounts = false;
      hasVouchers = false;
      isLoading = false;
    });
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
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final hasAnyAccount =
        hasCashAccounts || hasSavingsAccounts || hasInvestmentAccounts || hasVouchers;

    return Scaffold(
      appBar: AppBar(title: const Text("Patrimoine App")),
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
                if (hasCashAccounts)
                  CashAccountList(
                    userId: 1,
                    onAccountUpdated: _refreshAll,
                  ),
                if (hasSavingsAccounts)
                  SavingsAccountList(
                    userId: 1,
                    onAccountUpdated: _refreshAll,
                  ),
              ],
            )
                : const Center(
              child: Text(
                "Aucun compte disponible",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}