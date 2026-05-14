import 'package:flutter/material.dart';

import '../models/Budget/budget_category.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  // Tes couleurs officielles
  static const Color colorDarkBg = Color(0xFF060B26);
  static const Color colorGreenLogo = Color(0xFF2DB23A);
  static const Color colorRed = Color(0xFFFC5555);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorDarkBg,
      // Utilisation d'un CustomScrollView pour une liste élégante plus tard
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildHeader(),
            const SizedBox(height: 40),
            _buildQuickActions(),
            // Ici viendra ta liste de transactions plus tard
            const Expanded(
              child: Center(
                child: Text("Aucune transaction ce mois-ci",
                    style: TextStyle(color: Colors.white24)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text("SOLDE DU MOIS",
            style: TextStyle(color: Colors.white54, letterSpacing: 1.5, fontSize: 12)),
        const SizedBox(height: 8),
        const Text("2 450,00 €", // Exemple statique
            style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              label: "Revenu",
              icon: Icons.add_chart_rounded,
              color: colorGreenLogo,
              onTap: () => _showAddTransactionSheet(TransactionType.income),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _actionButton(
              label: "Dépense",
              icon: Icons.shopping_cart_checkout_rounded,
              color: colorRed,
              onTap: () => _showAddTransactionSheet(TransactionType.expense),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showAddTransactionSheet(TransactionType type) {
    // C'est ici que tu utiliseras tes modèles pour créer la transaction
    // et l'envoyer à Supabase
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                type == TransactionType.income ? "Nouveau Revenu" : "Nouvelle Dépense",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Ajoute ici tes TextField et ton sélecteur de catégorie
            ],
          ),
        ),
      ),
    );
  }
}