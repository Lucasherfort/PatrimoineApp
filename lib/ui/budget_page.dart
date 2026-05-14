import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/Budget/budget_category.dart';
import '../services/budget_service.dart';
import '../services/settings_service.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final BudgetService _budgetService = BudgetService();

  static const Color colorDarkBg = Color(0xFF060B26);
  static const Color colorBlueMain = Color(0xFF0D71EE);
  static const Color colorGreenLogo = Color(0xFF2DB23A);
  static const Color colorRed = Color(0xFFFC5555);
  static const Color colorOrangePerk = Color(0xFFFF9800); // Couleur pour les avantages

  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  double _totalBalance = 0;

  final SettingsService _settingsService = SettingsService();
  double _investableSurplus = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await _budgetService.getMonthlyTransactions();
      double target = await _settingsService.getTargetBalance(); // <-- Récupère ton 300€ (ou autre)

      // Tri : Revenus, puis Dépenses, puis Avantages
      data.sort((a, b) {
        final typeA = a['budget_category']['type'];
        final typeB = b['budget_category']['type'];
        if (typeA == 'income' && typeB != 'income') return -1;
        if (typeA == 'expense' && typeB == 'perk') return -1;
        return 1;
      });

      double balance = 0;
      for (var tx in data) {
        if (tx['budget_category'] != null) {
          final val = (tx['value'] as num).toDouble();
          final type = tx['budget_category']['type'];
          if (type == 'income') balance += val;
          else if (type == 'expense') balance -= val;
        }
      }

      setState(() {
        _transactions = data;
        _totalBalance = balance;
        _investableSurplus = _totalBalance - target; // <-- Ton vrai montant épargnable
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erreur Budget: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTx(String id) async {
    try {
      await _budgetService.deleteTransaction(id);
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur suppression: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorDarkBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: colorBlueMain,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
              SliverToBoxAdapter(child: _buildHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
              SliverToBoxAdapter(child: _buildQuickActions()),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
              _isLoading
                  ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: colorBlueMain)))
                  : _transactions.isEmpty
                  ? const SliverFillRemaining(child: Center(child: Text("Aucune transaction", style: TextStyle(color: Colors.white24))))
                  : _buildTransactionList(),
            ],
          ),
        ),
      ),
    );
  }

// Mise à jour du Header
  Widget _buildHeader() {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final currentMonth = DateFormat.MMMM('fr_FR').format(DateTime.now()).toUpperCase();

    return Column(
      children: [
        Text("SOLDE ACTUEL ESTIMÉ", style: TextStyle(color: Colors.white.withOpacity(0.4), letterSpacing: 1.5, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(currencyFormat.format(_totalBalance), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),

        // Petit badge de surplus
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _investableSurplus >= 0 ? colorGreenLogo.withOpacity(0.1) : colorRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (_investableSurplus >= 0 ? colorGreenLogo : colorRed).withOpacity(0.2)),
          ),
          child: Text(
            _investableSurplus >= 0
                ? "ÉPARGNABLE : ${currencyFormat.format(_investableSurplus)}"
                : "À RÉINJECTER : ${currencyFormat.format(_investableSurplus.abs())}",
            style: TextStyle(color: _investableSurplus >= 0 ? colorGreenLogo : colorRed, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _actionButton(label: "Revenu", icon: Icons.add_chart_rounded, color: colorGreenLogo, onTap: () => _showAddTransactionSheet(TransactionType.income))),
          const SizedBox(width: 12),
          Expanded(child: _actionButton(label: "Dépense", icon: Icons.shopping_cart_checkout_rounded, color: colorRed, onTap: () => _showAddTransactionSheet(TransactionType.expense))),
          const SizedBox(width: 12),
          Expanded(child: _actionButton(label: "Avantage", icon: Icons.card_giftcard_rounded, color: colorOrangePerk, onTap: () => _showAddTransactionSheet(TransactionType.perk))),
        ],
      ),
    );
  }

  Widget _actionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(children: [Icon(icon, color: color, size: 24), const SizedBox(height: 6), Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800))]),
      ),
    );
  }

  Widget _buildTransactionList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final tx = _transactions[index];
          final category = tx['budget_category'];
          final type = category['type'];

          Color amountColor;
          String prefix = "";

          if (type == 'expense') {
            amountColor = colorRed;
            prefix = "-";
          } else if (type == 'income') {
            amountColor = colorGreenLogo;
            prefix = "+";
          } else {
            amountColor = colorOrangePerk;
            prefix = "🍱 "; // Indicateur visuel pour Titres Resto / Avantages
          }

          return Dismissible(
            key: Key(tx['id'].toString()),
            direction: DismissDirection.endToStart,
            onDismissed: (dir) => _deleteTx(tx['id'].toString()),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: colorRed, borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: GestureDetector(
              onTap: () => _showAddTransactionSheet(
                  type == 'income' ? TransactionType.income : (type == 'expense' ? TransactionType.expense : TransactionType.perk),
                  existingTx: tx
              ),
              onLongPress: () => _showDeleteDialog(tx['id'].toString(), category['name']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.05))),
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: amountColor.withOpacity(0.1), child: Icon(_getIconData(category['icon']), color: amountColor, size: 20)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(category['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          if (tx['note'] != null && tx['note'].isNotEmpty) Text(tx['note'], style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                        ],
                      ),
                    ),
                    Text("$prefix${tx['value'].toStringAsFixed(2)} €", style: TextStyle(color: amountColor, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
          );
        }, childCount: _transactions.length),
      ),
    );
  }

  void _showDeleteDialog(String id, String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("Supprimer ?", style: TextStyle(color: Colors.white)),
        content: Text("Voulez-vous supprimer cette ligne de '$categoryName' ?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.white38))),
          TextButton(onPressed: () { Navigator.pop(context); _deleteTx(id); }, child: const Text("Supprimer", style: TextStyle(color: colorRed, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_cart': return Icons.shopping_cart_rounded;
      case 'home': return Icons.home_rounded;
      case 'phone_android': return Icons.phone_android_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'directions_car': return Icons.directions_car_rounded; // Pour Transport
      case 'confirmation_number': return Icons.confirmation_number_rounded; // Pour Titres Resto
      default: return Icons.category_rounded;
    }
  }

  void _showAddTransactionSheet(TransactionType type, {Map<String, dynamic>? existingTx}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTransactionForm(
        type: type,
        existingTx: existingTx,
        onSuccess: () { Navigator.pop(context); _loadData(); },
      ),
    );
  }
}

// --- FORMULAIRE D'AJOUT ET D'EDITION ---
class _AddTransactionForm extends StatefulWidget {
  final TransactionType type;
  final Map<String, dynamic>? existingTx;
  final VoidCallback onSuccess;
  const _AddTransactionForm({required this.type, this.existingTx, required this.onSuccess});

  @override
  State<_AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<_AddTransactionForm> {
  final BudgetService _service = BudgetService();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  List<BudgetCategory> _categories = [];
  BudgetCategory? _selectedCategory;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.existingTx?['value']?.toString() ?? "");
    _noteController = TextEditingController(text: widget.existingTx?['note'] ?? "");
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final all = await _service.getCategories();
    setState(() {
      _categories = all.where((c) => c.type == widget.type).toList();
      if (widget.existingTx != null) {
        _selectedCategory = _categories.firstWhere((c) => c.id == widget.existingTx!['category_id'].toString(), orElse: () => _categories.first);
      } else if (_categories.isNotEmpty) {
        _selectedCategory = _categories.first;
      }
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || _selectedCategory == null) return;
    setState(() => _isSaving = true);
    try {
      final tx = BudgetTransaction(
        userId: Supabase.instance.client.auth.currentUser!.id,
        categoryId: _selectedCategory!.id,
        value: amount,
        date: widget.existingTx != null ? DateTime.parse(widget.existingTx!['date']) : DateTime.now(),
        note: _noteController.text,
      );
      if (widget.existingTx != null) {
        await _service.updateTransaction(widget.existingTx!['id'].toString(), tx);
      } else {
        await _service.addTransaction(tx);
      }
      widget.onSuccess();
    } catch (e) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF0F172A), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Text(widget.existingTx != null ? "Modifier" : "Ajouter", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: InputDecoration(hintText: "0.00 €", filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 16),
          if (!_isLoading) Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<BudgetCategory>(
                value: _selectedCategory,
                dropdownColor: const Color(0xFF1E293B),
                isExpanded: true,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(controller: _noteController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Note", prefixIcon: const Icon(Icons.edit, color: Colors.white54), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _isSaving ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D71EE), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: _isSaving ? const CircularProgressIndicator() : const Text("VALIDER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }
}