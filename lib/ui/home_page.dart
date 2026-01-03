import 'package:flutter/material.dart';
import '../repositories/local_database_repository.dart';
import '../services/patrimoine_service.dart';
import '../widgets/patrimoine_header.dart';
import '../widgets/savings_account_list.dart';
import '../widgets/investment_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double patrimoineTotal = 0.0;
  bool isLoading = true;
  List<UserSavingsAccountView> userAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadPatrimoine();
  }

  Future<void> _loadPatrimoine() async {
    final repo = LocalDatabaseRepository();
    final db = await repo.load();
    final service = PatrimoineService(db);

    final total = service.getTotalPatrimoineForUser(1);
    final accounts = service.getAccountsForUser(1);

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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PatrimoineHeader(patrimoineTotal: patrimoineTotal),
            SavingsAccountList(accounts: userAccounts),
            const InvestmentList(userId: 1), // ✅ Ajout du userId
          ],
        ),
      ),
    );
  }
}
