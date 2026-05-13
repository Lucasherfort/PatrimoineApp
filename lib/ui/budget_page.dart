import 'package:flutter/material.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetViewState();
}

class _BudgetViewState extends State<BudgetPage> {
  double salary = 3000.0;
  double mealVouchers = 200.0;
  List<Map<String, dynamic>> expenses = [
    {'title': 'Loyer', 'amount': 800.0},
    {'title': 'Courses', 'amount': 300.0},
  ];

  double get totalExpenses => expenses.fold(0, (sum, item) => sum + item['amount']);
  double get remaining => (salary + mealVouchers) - totalExpenses;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCard(), // Carte affichant le "Reste à épargner"
          const SizedBox(height: 20),
          _buildInputSection("Revenus", Icons.trending_up, [
            {'label': 'Salaire', 'value': salary},
            {'label': 'Tickets Resto', 'value': mealVouchers},
          ]),
          const SizedBox(height: 20),
          _buildExpensesList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade700, Colors.teal.shade900]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text("Capacité d'épargne", style: TextStyle(color: Colors.white70)),
          Text("${remaining.toStringAsFixed(2)}€",
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  _buildInputSection(String s, IconData trending_up, List<Map<String, Object>> list) {}

  _buildExpensesList() {}
}