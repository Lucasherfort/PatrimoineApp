import 'package:flutter/material.dart';
import '../repositories/local_database_repository.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPatrimoine();
  }

  Future<void> _loadPatrimoine() async {
    setState(() => isLoading = true);

    final repo = LocalDatabaseRepository();
    final db = await repo.load();
    final service = PatrimoineService(db);

    final total = await service.getTotalPatrimoineForUser(userId);

    setState(() {
      patrimoineTotal = total;
      isLoading = false;
    });
  }

  Future<void> _refreshAll() async {
    await _loadPatrimoine();
    setState(() {}); // pour forcer le rebuild
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
    return Scaffold(
      appBar: AppBar(title: const Text("Patrimoine App")),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPatrimoinePanel,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // ✅ HEADER FIXE
          PatrimoineHeader(
            patrimoineTotal: patrimoineTotal,
            onRefresh: _refreshAll,
          ),

          // ✅ CONTENU SCROLLABLE
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                CashAccountList(
                  userId: userId,
                  onAccountUpdated: _refreshAll,
                ),
                SavingsAccountList(
                  userId: userId,
                  onAccountUpdated: _refreshAll,
                ),
                InvestmentList(
                  userId: userId,
                  onAccountTap: _refreshAll,
                ),
                RestaurantVoucherList(
                  userId: userId,
                  onVoucherUpdated: _refreshAll,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
