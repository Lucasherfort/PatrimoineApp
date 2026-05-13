import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/patrimoine_service.dart';
import '../widgets/Investment/investment_list.dart';
import '../widgets/Savings/savings_account_list.dart';
import '../widgets/advantage/advantage_account_list.dart';
import '../widgets/patrimoine/add_patrimoine_wizard.dart';
import '../widgets/Liquidity/liquidity_account_list.dart';
import '../widgets/patrimoine/patrimoine_header.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  final String appName;
  final String appVersion;

  const HomePage({super.key, required this.appName, required this.appVersion});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PatrimoineService _service = PatrimoineService();
  int _selectedIndex = 0; // 0 = Patrimoine, 1 = Budget

  // Données Patrimoine
  double patrimoineTotal = 0.0;
  double totalDepose = 0.0;
  double capitalOwned = 0.0;
  double patrimoineOwned = 0.0;
  bool isLoading = true;

  bool hasLiquidityAccounts = false;
  bool hasSavingsAccounts = false;
  bool hasInvestmentAccounts = false;
  bool hasAdvantageAccounts = false;

  // Données Budget (À lier à une table Supabase plus tard)
  double salary = 2500.0;
  double mealVouchers = 180.0;
  List<Map<String, dynamic>> expenses = [
    {'name': 'Loyer', 'amount': 850.0},
    {'name': 'Courses', 'amount': 400.0},
    {'name': 'Abonnements', 'amount': 50.0},
  ];

  @override
  void initState() {
    super.initState();
    _loadPatrimoine();
  }

  Future<void> _loadPatrimoine() async {
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
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  // --- LOGIQUE BUDGET ---
  double get totalExpenses => expenses.fold(0, (sum, item) => sum + item['amount']);
  double get savingsCapacity => (salary + mealVouchers) - totalExpenses;

  // --- ACTIONS ---
  void _openAddPatrimoinePanel() async {
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
    if (result == true) _loadPatrimoine();
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous quitter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui')),
        ],
      ),
    );
    if (shouldLogout == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A), Colors.black],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : IndexedStack(
            index: _selectedIndex,
            children: [
              _buildPatrimoineTab(),
              _buildBudgetTab(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- WIDGETS DE SECTIONS ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Text(widget.appName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          _buildVersionBadge(),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.white), onPressed: _openAddPatrimoinePanel),
        IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout),
      ],
    );
  }

  Widget _buildVersionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(widget.appVersion, style: const TextStyle(fontSize: 10, color: Colors.white70)),
    );
  }

  Widget _buildPatrimoineTab() {
    final hasAnyAccount = hasLiquidityAccounts || hasSavingsAccounts || hasInvestmentAccounts || hasAdvantageAccounts;
    return Column(
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
              ? ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (hasLiquidityAccounts) LiquidityAccountList(onAccountUpdated: _loadPatrimoine),
              if (hasSavingsAccounts) SavingsAccountList(onAccountUpdated: _loadPatrimoine),
              if (hasInvestmentAccounts) InvestmentList(onAccountUpdated: _loadPatrimoine),
              if (hasAdvantageAccounts) AdvantageAccountList(onAccountUpdated: _loadPatrimoine),
            ],
          )
              : const Center(child: Text("Aucun compte", style: TextStyle(color: Colors.white54))),
        ),
      ],
    );
  }

  Widget _buildBudgetTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Carte Résumé
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade600]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Text("Reste à épargner", style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              Text("${savingsCapacity.toStringAsFixed(2)} €",
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 30),
        _buildSectionTitle("Entrées d'argent"),
        _buildBudgetTile("Salaire", salary, Icons.euro, Colors.green),
        _buildBudgetTile("Tickets Resto", mealVouchers, Icons.restaurant, Colors.orange),
        const SizedBox(height: 24),
        _buildSectionTitle("Dépenses mensuelles"),
        ...expenses.map((e) => _buildBudgetTile(e['name'], e['amount'], Icons.remove_circle_outline, Colors.redAccent)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {}, // Action pour ajouter une dépense
          icon: const Icon(Icons.add),
          label: const Text("Ajouter une dépense"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white),
        )
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBudgetTile(String title, double amount, IconData icon, Color color) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: Text("${amount.toStringAsFixed(2)} €",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      backgroundColor: const Color(0xFF0F172A),
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.white38,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Patrimoine'),
        BottomNavigationBarItem(icon: Icon(Icons.wallet_outlined), label: 'Budget'),
      ],
    );
  }
}