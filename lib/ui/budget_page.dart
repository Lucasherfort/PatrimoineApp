import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/budget/budget_category.dart';
import '../models/budget/budget_item.dart';
import '../services/budget_service.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final BudgetService _budgetService = BudgetService();

  String _formatAmount(double amount, {bool includeSymbol = true}) {
    final formatter = NumberFormat("#,##0.00", "fr_FR");
    final formatted = formatter
        .format(amount)
        .replaceAll(RegExp(r'[\s\u00A0\u202F]'), '\u2007');
    return includeSymbol ? "$formatted €" : formatted;
  }

  List<BudgetItem> _items = [];
  List<BudgetCategory> _categories = [];
  bool _isLoading = true;
  bool _isVisible = true; // 👈 Ajouté pour gérer la visibilité des montants

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final items = await _budgetService.getBudgetItems();
      final categories = await _budgetService.getCategories();
      if (mounted) {
        setState(() {
          _items = items;
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalIncome => _items
      .where((i) => i.category?.type == BudgetType.income)
      .fold(0.0, (sum, i) => sum + i.amount);

  double get _totalExpense => _items
      .where((i) => i.category?.type == BudgetType.expense)
      .fold(0.0, (sum, i) => sum + i.amount);

  double get _savingsCapacity => _totalIncome - _totalExpense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const colorBlue = Color(0xFF0D71EE);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF060B26)
          : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // --- BACKGROUND HALOS ---
          Positioned(
            top: -50,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorBlue.withValues(alpha: isDark ? 0.12 : 0.07),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: colorBlue),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: Colors.white,
                          backgroundColor: colorBlue,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                if (_items.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _buildBudgetChart(isDark),
                                  const SizedBox(height: 32),
                                ],
                                _buildFlowSection(
                                  context,
                                  title: "REVENUS",
                                  type: BudgetType.income,
                                  color: Colors.green,
                                ),
                                const SizedBox(height: 32),
                                _buildFlowSection(
                                  context,
                                  title: "DÉPENSES",
                                  type: BudgetType.expense,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(height: 100), // Spacing for FAB
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFlowDialog(context),
        backgroundColor: colorBlue,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "BUDGET MENSUEL",
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.black38,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      "Flux financiers",
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _isVisible = !_isVisible),
                      icon: Icon(
                        _isVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: isDark ? Colors.white24 : Colors.black12,
                        size: 18,
                      ),
                      padding: const EdgeInsets.only(left: 8),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              _buildSavingsPill(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetChart(bool isDark) {
    final expensesByCat = <String, double>{};
    for (var item in _items.where(
      (i) => i.category?.type == BudgetType.expense,
    )) {
      final label = item.category?.label ?? "Autre";
      expensesByCat[label] = (expensesByCat[label] ?? 0) + item.amount;
    }

    if (expensesByCat.isEmpty) return const SizedBox();

    final totalExpense = expensesByCat.values.fold(0.0, (a, b) => a + b);

    // Sort categories by amount descending
    final sortedEntries = expensesByCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<Color> chartColors = [
      const Color(0xFF0D71EE),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFF6366F1),
    ];

    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: RepaintBoundary(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: sortedEntries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final value = entry.value.value;
                    final percentage = (value / totalExpense * 100);

                    return PieChartSectionData(
                      color: chartColors[index % chartColors.length],
                      value: value,
                      title: percentage >= 8 ? '${percentage.toInt()}%' : '',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sortedEntries.take(4).toList().asMap().entries.map((
                entry,
              ) {
                final index = entry.key;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: chartColors[index % chartColors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.value.key,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatAmount(entry.value.value),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D71EE).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.savings_rounded, size: 14, color: Color(0xFF0D71EE)),
          const SizedBox(width: 8),
          Text(
            _isVisible
                ? "${_formatAmount(_savingsCapacity, includeSymbol: false)} / mois"
                : "•••• €",
            style: const TextStyle(
              color: Color(0xFF0D71EE),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowSection(
    BuildContext context, {
    required String title,
    required BudgetType type,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionItems = _items.where((i) => i.category?.type == type).toList();
    final total = sectionItems.fold(0.0, (sum, i) => sum + i.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              _isVisible ? _formatAmount(total) : "•••• €",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (sectionItems.isEmpty)
          _buildEmptyState(
            context,
            type == BudgetType.income
                ? "Aucun revenu renseigné"
                : "Aucune dépense renseignée",
          )
        else
          ...sectionItems.map((item) => _buildFlowCard(context, item, color)),
      ],
    );
  }

  Widget _buildFlowCard(BuildContext context, BudgetItem item, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showAddFlowDialog(context, item: item),
      onLongPress: () => _confirmDelete(context, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.02),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getIconData(item.category?.icon),
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    item.category?.label ?? "Autre",
                    style: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _isVisible ? _formatAmount(item.amount) : "••• €",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, BudgetItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Supprimer ?",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text("Voulez-vous vraiment supprimer '${item.label}' ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "ANNULER",
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _deleteItem(item.id);
              Navigator.pop(context);
            },
            child: const Text(
              "SUPPRIMER",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: isDark ? Colors.white10 : Colors.black12,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteItem(String id) async {
    await _budgetService.deleteBudgetItem(id);
    _loadData();
  }

  void _showAddFlowDialog(BuildContext context, {BudgetItem? item}) {
    final labelController = TextEditingController(text: item?.label);
    final amountController = TextEditingController(
      text: item != null ? item.amount.toString().replaceAll('.', ',') : '',
    );
    BudgetType selectedType = item?.category?.type ?? BudgetType.expense;
    BudgetCategory? selectedCategory = item?.category;
    const colorBlue = Color(0xFF0D71EE);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredCategories = _categories
              .where((c) => c.type == selectedType)
              .toList();

          if (selectedCategory == null && filteredCategories.isNotEmpty) {
            selectedCategory = filteredCategories.first;
          } else if (selectedCategory != null &&
              selectedCategory!.type != selectedType) {
            selectedCategory = filteredCategories.isNotEmpty
                ? filteredCategories.first
                : null;
          }

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            padding: EdgeInsets.only(
              left: 28,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  item == null ? "Ajouter un flux" : "Modifier le flux",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Choice Chips
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeChip(
                        label: "REVENU",
                        isSelected: selectedType == BudgetType.income,
                        color: Colors.green,
                        onTap: () => setModalState(() {
                          selectedType = BudgetType.income;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeChip(
                        label: "DÉPENSE",
                        isSelected: selectedType == BudgetType.expense,
                        color: Colors.redAccent,
                        onTap: () => setModalState(() {
                          selectedType = BudgetType.expense;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: labelController,
                  autofocus: item == null,
                  decoration: InputDecoration(
                    labelText: "Libellé",
                    hintText: "Salaire, Loyer, Courses...",
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.02),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: "Montant mensuel",
                    suffixText: "€",
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.02),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<BudgetCategory>(
                  initialValue:
                      selectedCategory != null &&
                          filteredCategories.any(
                            (c) => c.id == selectedCategory!.id,
                          )
                      ? filteredCategories.firstWhere(
                          (c) => c.id == selectedCategory!.id,
                        )
                      : (filteredCategories.isNotEmpty
                            ? filteredCategories.first
                            : null),
                  decoration: InputDecoration(
                    labelText: "Catégorie",
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.02),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: filteredCategories
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(
                                _getIconData(cat.icon),
                                size: 18,
                                color: colorBlue,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                cat.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setModalState(() => selectedCategory = val),
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final cleanAmount = amountController.text.replaceAll(
                        ',',
                        '.',
                      );
                      final amount = double.tryParse(cleanAmount);
                      if (labelController.text.isNotEmpty &&
                          amount != null &&
                          selectedCategory != null) {
                        if (item == null) {
                          await _budgetService.addBudgetItem(
                            categoryId: selectedCategory!.id,
                            label: labelController.text,
                            amount: amount,
                          );
                        } else {
                          await _budgetService.updateBudgetItem(
                            id: item.id,
                            categoryId: selectedCategory!.id,
                            label: labelController.text,
                            amount: amount,
                          );
                        }
                        if (context.mounted) Navigator.pop(context);
                        _loadData();
                      }
                    },
                    child: Text(
                      item == null ? "ENREGISTRER" : "METTRE À JOUR",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? color : Colors.grey,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String? name) {
    switch (name) {
      case 'work_outline':
        return Icons.work_outline;
      case 'pie_chart_outline':
        return Icons.pie_chart_outline;
      case 'vpn_key_outlined':
        return Icons.vpn_key_outlined;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'home_outlined':
        return Icons.home_outlined;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car_filled_outlined':
        return Icons.directions_car_filled_outlined;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'celebration_outlined':
        return Icons.celebration_outlined;
      case 'security':
        return Icons.security;
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.help_outline;
    }
  }
}
