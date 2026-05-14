import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/Budget/budget_category.dart';
import '../services/budget_service.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final BudgetService _budgetService = BudgetService();

  // --- Palette de couleurs ---
  static const Color colorDarkBg = Color(0xFF060B26);
  static const Color colorBlueMain = Color(0xFF0D71EE);
  static const Color colorGreen = Color(0xFF2DB23A);
  static const Color colorRed = Color(0xFFFC5555);
  static const Color colorOrangePerk = Color(0xFFFF9800);

  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  Map<String, Map<String, dynamic>> _categoryTotals = {};
  double _totalBalance = 0;

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

      double balance = 0;
      Map<String, Map<String, dynamic>> totals = {};

      for (var tx in data) {
        final cat = tx['budget_category'];
        if (cat != null) {
          final val = (tx['value'] as num).toDouble();
          final type = cat['type'];
          final catName = cat['name'] as String;

          // 1. Calcul du solde (uniquement income et expense)
          if (type == 'income') {
            balance += val;
          } else if (type == 'expense') {
            balance -= val;
          }

          // 2. Aggrégation pour le Dashboard
          if (!totals.containsKey(catName)) {
            totals[catName] = {
              'sum': 0.0,
              'count': 0,
              'icon': cat['icon'],
              'type': type
            };
          }
          totals[catName]!['sum'] += val;
          totals[catName]!['count'] += 1;
        }
      }

      setState(() {
        _transactions = data;
        _categoryTotals = totals;
        _totalBalance = balance;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erreur Budget: $e");
      setState(() => _isLoading = false);
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
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              SliverToBoxAdapter(child: _buildHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),

              // --- DASHBOARD : SYNTHÈSE PAR CATÉGORIE ---
              if (!_isLoading && _categoryTotals.isNotEmpty)
                SliverToBoxAdapter(child: _buildCategoryDashboard()),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
              SliverToBoxAdapter(child: _buildQuickActions()),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, 12),
                  child: Text("HISTORIQUE DÉTAILLÉ",
                      style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                ),
              ),

              _isLoading
                  ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: colorBlueMain)))
                  : _transactions.isEmpty
                  ? const SliverFillRemaining(child: Center(child: Text("Aucune donnée", style: TextStyle(color: Colors.white24))))
                  : _buildTransactionList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    return Column(
      children: [
        Text("SOLDE INVESTISSABLE",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1.2, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(currencyFormat.format(_totalBalance),
            style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildCategoryDashboard() {
    final categories = _categoryTotals.keys.toList();
    return SizedBox(
      height: 115,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final name = categories[index];
          final data = _categoryTotals[name]!;
          final isIncome = data['type'] == 'income';
          final isPerk = data['type'] == 'perk';

          Color accentColor = isIncome ? colorGreen : (isPerk ? colorOrangePerk : colorBlueMain);

          return Container(
            width: 155,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Icon(_getIconData(data['icon']), color: accentColor, size: 18),
                    ),
                    Text("${data['count']} lignes", style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1),
                    Text("${data['sum'].toStringAsFixed(2)}€",
                        style: TextStyle(color: isIncome ? colorGreen : Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _actionBtn("Revenu", Icons.add_rounded, colorGreen, TransactionType.income),
          const SizedBox(width: 10),
          _actionBtn("Dépense", Icons.remove_rounded, colorRed, TransactionType.expense),
          const SizedBox(width: 10),
          _actionBtn("Perk", Icons.star_rounded, colorOrangePerk, TransactionType.perk),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, TransactionType type) {
    return Expanded(
      child: InkWell(
        onTap: () => _showAddTransactionSheet(type),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final tx = _transactions[index];
          final category = tx['budget_category'];
          final type = category['type'];
          final isExpense = type == 'expense';
          final isIncome = type == 'income';

          Color color = isIncome ? colorGreen : (isExpense ? colorRed : colorOrangePerk);

          return Dismissible(
            key: Key(tx['id'].toString()),
            direction: DismissDirection.endToStart,
            onDismissed: (dir) => _deleteTx(tx['id'].toString()),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(color: colorRed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.delete_outline, color: colorRed),
            ),
            child: GestureDetector(
              onTap: () => _showAddTransactionSheet(
                  isIncome ? TransactionType.income : (isExpense ? TransactionType.expense : TransactionType.perk),
                  existingTx: tx
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Icon(_getIconData(category['icon']), color: color.withValues(alpha: 0.5), size: 22),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(category['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                          if (tx['note'] != null && tx['note'].isNotEmpty)
                            Text(tx['note'], style: TextStyle(color: Colors.white24, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text("${isIncome ? '+' : (isExpense ? '-' : '')}${tx['value'].toStringAsFixed(2)} €",
                        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
                  ],
                ),
              ),
            ),
          );
        }, childCount: _transactions.length),
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'work': return Icons.work_rounded;
      case 'shopping_cart': return Icons.shopping_cart_rounded;
      case 'food': return Icons.restaurant_rounded;
      case 'home': return Icons.home_rounded;
      case 'phone_android': return Icons.phone_android_rounded;
      case 'directions_car': return Icons.directions_car_rounded;
      case 'account_balance': return Icons.account_balance_rounded;
      case 'smart_display': return Icons.smart_display_rounded;
      case 'security': return Icons.security_rounded;
      default: return Icons.category_rounded;
    }
  }

  // --- LOGIQUE SERVICES ---
  Future<void> _deleteTx(String id) async {
    try {
      await _budgetService.deleteTransaction(id);
      if (!mounted) return;
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
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

// --- FORMULAIRE (IDENTIQUE MAIS STYLE MODAL AJUSTÉ) ---
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF111827), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Text(widget.existingTx != null ? "Modifier" : "Nouvelle entrée", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
            decoration: InputDecoration(hintText: "0.00", hintStyle: TextStyle(color: Colors.white10), border: InputBorder.none),
          ),
          const SizedBox(height: 24),
          if (!_isLoading) _buildCategoryPicker(),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Note ou description",
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(backgroundColor: _BudgetPageState.colorBlueMain, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
              child: const Text("SAUVEGARDER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _categories.map((c) {
        final isSelected = _selectedCategory?.id == c.id;
        return ChoiceChip(
          label: Text(c.name),
          selected: isSelected,
          onSelected: (s) => setState(() => _selectedCategory = c),
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          selectedColor: _BudgetPageState.colorBlueMain.withValues(alpha: 0.2),
          labelStyle: TextStyle(color: isSelected ? _BudgetPageState.colorBlueMain : Colors.white60, fontSize: 12),
          side: BorderSide(color: isSelected ? _BudgetPageState.colorBlueMain : Colors.transparent),
        );
      }).toList(),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || _selectedCategory == null) return;
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
      if (kDebugMode) {
        print(e);
      }
    }
  }
}