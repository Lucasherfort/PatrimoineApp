import 'package:flutter/material.dart';
import '../repositories/local_database_repository.dart';
import '../services/patrimoine_service.dart';
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
  List<UserSavingsAccountView> userAccounts = [];

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
    final accounts = service.getAccountsForUser(userId);

    setState(() {
      patrimoineTotal = total;
      userAccounts = accounts;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patrimoine App"),
        elevation: 0,
        actions: [
          // ✅ Bouton refresh manuel
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatrimoine,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PatrimoineHeader(patrimoineTotal: patrimoineTotal),
            CashAccountList(userId: userId),
            SavingsAccountList(accounts: userAccounts),
            InvestmentList(
              userId: userId,
              onAccountTap: _onInvestmentAccountTap, // ✅ Callback
            ),
            RestaurantVoucherList(userId: userId),
          ],
        ),
      ),
    );
  }

  // ✅ Méthode appelée quand on clique sur un compte d'investissement
  Future<void> _onInvestmentAccountTap() async {
    // Attend le retour de la page de détail
    // Si elle retourne true, on recharge
    _loadPatrimoine();
  }
}
