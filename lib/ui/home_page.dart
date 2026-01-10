import 'package:flutter/material.dart';
import '../services/patrimoine_service.dart';
import '../widgets/add_patrimoine_wizard.dart';
import '../widgets/patrimoine_header.dart';
import '../widgets/cash_account_list.dart';
import '../widgets/savings_account_list.dart';
import '../widgets/investment_list.dart';
import '../widgets/restaurant_voucher_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int userId = 1;
  double patrimoineTotal = 0.0;
  bool isLoading = true;

  // ✅ Suivi des comptes par catégorie
  bool hasCashAccounts = false;
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

    // 🔹 Total patrimoine
    final total = await service.getTotalPatrimoineForUser(userId);

    // 🔹 Vérifier présence des comptes

    hasCashAccounts = db.userCashAccounts.any((ua) => ua.userId == userId);
    hasSavingsAccounts = db.userSavingsAccounts.any((ua) => ua.userId == userId);
    hasInvestmentAccounts = db.userInvestmentAccounts.any((ua) => ua.userId == userId);
    hasVouchers = db.userRestaurantVouchers.any((ua) => ua.userId == userId);



    setState(() {
      patrimoineTotal = total;
      isLoading = false;
    });
  }

  Future<void> _refreshAll() async {
    await _loadPatrimoine();
    setState(() {}); // rebuild pour rafraîchir l'affichage
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
          // ✅ HEADER FIXE
          PatrimoineHeader(
            patrimoineTotal: patrimoineTotal,
            onRefresh: _refreshAll,
          ),

          // ✅ CONTENU SCROLLABLE
          Expanded(
            child: hasAnyAccount
                ? ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                if (hasCashAccounts)
                  CashAccountList(
                    userId: userId,
                    onAccountUpdated: _refreshAll,
                  ),
                if (hasSavingsAccounts)
                  SavingsAccountList(
                    userId: userId,
                    onAccountUpdated: _refreshAll,
                  ),
                if (hasInvestmentAccounts)
                  InvestmentList(
                    userId: userId,
                    onAccountTap: _refreshAll,
                    onAccountUpdated: _refreshAll,
                  ),
                if (hasVouchers)
                  RestaurantVoucherList(
                    userId: userId,
                    onVoucherUpdated: _refreshAll,
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
