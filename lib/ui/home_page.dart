import 'package:flutter/material.dart';
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
  // ✅ Simple instanciation sans dépendance Supabase
  final PatrimoineService _service = PatrimoineService();

  double patrimoineTotal = 0.0;
  bool isLoading = true;

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

    try {
      final total = await _service.getPatrimoine();

      setState(() {
        patrimoineTotal = total;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement du patrimoine: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _refreshAll() async {
    await _loadPatrimoine();
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasAnyAccount = hasCashAccounts ||
        hasSavingsAccounts ||
        hasInvestmentAccounts ||
        hasVouchers;

    return Scaffold(
      appBar: AppBar(title: const Text("Patrimoine App")),
      /*
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPatrimoinePanel,
        child: const Icon(Icons.add),
      ),

       */
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