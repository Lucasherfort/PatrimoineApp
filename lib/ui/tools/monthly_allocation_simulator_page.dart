import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/budget_service.dart';
import '../../services/liquidity_service.dart';
import '../../services/savings_account_service.dart';
import '../../services/investment_service.dart';
import '../../models/liquidity/user_liquidity_account_view.dart';
import '../../models/savings/user_savings_account_view.dart';
import '../../models/investments/user_investment_account_view.dart';

enum AllocationType { fixedAmount, percentage }

class AllocationTarget {
  final String id;
  String name;
  AllocationType type;
  double value; // Montant en € ou Pourcentage en %
  final String accountType; // 'ccp', 'savings', 'pea'
  final int accountId;
  final bool isSystem; // true pour les CCP (non supprimable, montant fixe obligatoire en €)
  final dynamic rawAccount;

  AllocationTarget({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.accountType,
    required this.accountId,
    this.isSystem = false,
    this.rawAccount,
  });
}

class MonthlyAllocationSimulatorPage extends StatefulWidget {
  const MonthlyAllocationSimulatorPage({super.key});

  @override
  State<MonthlyAllocationSimulatorPage> createState() =>
      _MonthlyAllocationSimulatorPageState();
}

class _MonthlyAllocationSimulatorPageState
    extends State<MonthlyAllocationSimulatorPage> {
  static const Color colorBlue = Color(0xFF0D71EE);

  final _totalLiquidityController = TextEditingController(text: "0");
  final _fixedExpensesController = TextEditingController(text: "0");

  bool _isLoading = true;
  bool _isApplying = false;

  List<UserLiquidityAccountView> _liquidityAccounts = [];
  List<UserSavingsAccountView> _savingsAccounts = [];
  List<UserInvestmentAccountView> _investmentAccounts = [];

  final List<AllocationTarget> _targets = [];

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final liquidityService = LiquidityService();
      final savingsService = SavingsAccountService();
      final investmentService = InvestmentService();
      final budgetService = BudgetService();

      _liquidityAccounts = await liquidityService.getUserLiquidityAccounts();
      _savingsAccounts = await savingsService.getUserSavingsAccounts();
      _investmentAccounts =
          await investmentService.getInvestmentAccountsForUserWithPrices();

      double totalCcp = await liquidityService.getTotalLiquidityValue();
      double fixedExpenses = await budgetService.getTotalOutgoings();

      _totalLiquidityController.text =
          totalCcp.toStringAsFixed(2).replaceAll('.', ',');
      _fixedExpensesController.text =
          fixedExpenses.toStringAsFixed(2).replaceAll('.', ',');

      _targets.clear();

      // 1. Ajouter TOUS les comptes CCP en premier (système, non supprimables, montant fixe en €)
      for (final ccp in _liquidityAccounts) {
        _targets.add(
          AllocationTarget(
            id: 'ccp_${ccp.id}',
            name: '${ccp.sourceName} - ${ccp.bankName}',
            type: AllocationType.fixedAmount,
            value: 400.0,
            accountType: 'ccp',
            accountId: ccp.id,
            isSystem: true,
            rawAccount: ccp,
          ),
        );
      }

      // S'il n'y a aucun CCP en base, ajouter un CCP par défaut
      if (_liquidityAccounts.isEmpty) {
        _targets.add(
          AllocationTarget(
            id: 'ccp_default',
            name: 'Compte Courant (CCP)',
            type: AllocationType.fixedAmount,
            value: 400.0,
            accountType: 'ccp',
            accountId: 0,
            isSystem: true,
          ),
        );
      }

      // 2. Ajouter des cibles par défaut (PEA et Livret A en pourcentage) si l'utilisateur en a
      final pea = _investmentAccounts
          .where((a) => a.sourceName.toUpperCase().contains('PEA'))
          .firstOrNull;
      if (pea != null) {
        _targets.add(
          AllocationTarget(
            id: 'pea_${pea.id}',
            name: '${pea.sourceName} - ${pea.bankName}',
            type: AllocationType.percentage,
            value: 80.0,
            accountType: 'pea',
            accountId: pea.id,
            rawAccount: pea,
          ),
        );
      }

      final savings = _savingsAccounts.firstOrNull;
      if (savings != null) {
        _targets.add(
          AllocationTarget(
            id: 'savings_${savings.id}',
            name: '${savings.sourceName} - ${savings.bankName}',
            type: AllocationType.percentage,
            value: 20.0,
            accountType: 'savings',
            accountId: savings.id,
            rawAccount: savings,
          ),
        );
      }
    } catch (e) {
      // Ignorer
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _totalLiquidityController.dispose();
    _fixedExpensesController.dispose();
    super.dispose();
  }

  double get _totalLiquidity =>
      double.tryParse(_totalLiquidityController.text.replaceAll(',', '.')) ??
      0.0;
  double get _fixedExpenses =>
      double.tryParse(_fixedExpensesController.text.replaceAll(',', '.')) ?? 0.0;

  double get _remainingAfterExpenses =>
      (_totalLiquidity - _fixedExpenses).clamp(0.0, double.infinity);

  // Calcul des répartitions (le pourcentage s'applique sur le restant après dépenses fixes + cibles ccp déduites)
  Map<String, double> get _calculatedAllocations {
    double surplus = _remainingAfterExpenses;
    final Map<String, double> results = {};

    // 1. D'abord déduire tous les montants fixes (CCP et autres fixes)
    for (final target in _targets.where((t) => t.type == AllocationType.fixedAmount)) {
      final allocated = target.value.clamp(0.0, surplus);
      results[target.id] = allocated;
      surplus = (surplus - allocated).clamp(0.0, double.infinity);
    }

    // 2. Ensuite répartir le reste selon les pourcentages
    final percentageTargets =
        _targets.where((t) => t.type == AllocationType.percentage).toList();
    final totalPercentage =
        percentageTargets.fold<double>(0.0, (sum, t) => sum + t.value);

    for (final target in percentageTargets) {
      if (totalPercentage > 0 && surplus > 0) {
        final share = (target.value / totalPercentage) * surplus;
        results[target.id] = share;
      } else {
        results[target.id] = 0.0;
      }
    }

    return results;
  }

  void _addAccountTargetDialog() async {
    dynamic selectedAccount;
    double value = 50.0;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final List<dynamic> availableAccounts = [
            ..._savingsAccounts.map((s) => {'type': 'savings', 'obj': s, 'name': '${s.sourceName} - ${s.bankName}'}),
            ..._investmentAccounts
                .where((i) => i.sourceName.toUpperCase().contains('PEA'))
                .map((i) => {'type': 'pea', 'obj': i, 'name': '${i.sourceName} - ${i.bankName}'}),
          ];

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Ajouter un compte cible"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (availableAccounts.isEmpty)
                  const Text(
                    "Aucun compte d'épargne ou PEA disponible. Veuillez d'abord en créer un.",
                    style: TextStyle(color: Colors.redAccent),
                  )
                else
                  DropdownButtonFormField<dynamic>(
                    value: selectedAccount,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: "Sélectionner un compte"),
                    items: availableAccounts.map((acc) {
                      return DropdownMenuItem<dynamic>(
                        value: acc,
                        child: Text(
                          acc['name'],
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedAccount = val);
                    },
                  ),
                const SizedBox(height: 16),
                TextField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Pourcentage (%)",
                  ),
                  onChanged: (val) =>
                      value = double.tryParse(val.replaceAll(',', '.')) ?? 0.0,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: selectedAccount == null
                    ? null
                    : () {
                        final acc = selectedAccount;
                        final typeStr = acc['type'] as String;
                        final obj = acc['obj'];
                        final name = acc['name'] as String;
                        final id = obj.id.toString();

                        setState(() {
                          _targets.removeWhere((t) => t.accountId.toString() == id && t.accountType == typeStr);
                          _targets.add(
                            AllocationTarget(
                              id: '${typeStr}_$id',
                              name: name,
                              type: AllocationType.percentage,
                              value: value,
                              accountType: typeStr,
                              accountId: obj.id,
                              isSystem: false,
                              rawAccount: obj,
                            ),
                          );
                        });
                        Navigator.pop(ctx);
                      },
                child: const Text("Ajouter"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _applyAllocation() async {
    final allocations = _calculatedAllocations;
    final validTargets = _targets
        .where((t) => t.accountType != 'ccp' && (allocations[t.id] ?? 0.0) > 0)
        .toList();

    if (validTargets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aucun virement valide à appliquer vers un compte cible."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final totalTransfer = validTargets.fold<double>(
      0.0,
      (sum, t) => sum + (allocations[t.id] ?? 0.0),
    );

    if (totalTransfer > _totalLiquidity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Le total à virer dépasse le solde liquide disponible."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Appliquer la répartition"),
        content: Text(
          "Voulez-vous effectuer les virements automatiques pour un total de ${_currency.format(totalTransfer)} depuis votre compte liquide vers vos comptes cibles ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirmer les virements"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isApplying = true);

    try {
      final liquidityService = LiquidityService();
      final savingsService = SavingsAccountService();
      final investmentService = InvestmentService();

      // 1. Débiter le compte liquide source
      if (_liquidityAccounts.isNotEmpty) {
        final sourceCcp = _liquidityAccounts.first;
        final newCcpAmount = sourceCcp.amount - totalTransfer;
        await liquidityService.updateAmount(
          accountId: sourceCcp.id,
          amount: newCcpAmount,
        );
      }

      // 2. Créditer chaque compte cible
      for (final target in validTargets) {
        final amount = allocations[target.id] ?? 0.0;
        if (amount <= 0) continue;

        if (target.accountType == 'savings') {
          final savings = target.rawAccount as UserSavingsAccountView;
          final newPrincipal = savings.principal + amount;
          await savingsService.updateSavingsAccount(
            savingsAccountId: savings.id,
            principal: newPrincipal,
            interest: savings.interest,
            automaticInterestCalculation: false,
          );
        } else if (target.accountType == 'pea') {
          final pea = target.rawAccount as UserInvestmentAccountView;
          final newCash = pea.cashBalance + amount;
          await investmentService.updateInvestmentAccount(
            userInvestmentAccountId: pea.id,
            cashBalance: newCash,
            cumulativeDeposits: pea.totalContribution,
            openedAt: pea.openedAt,
          );
        }
      }

      if (!mounted) return;

      setState(() => _isApplying = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Répartition appliquée et virements effectués avec succès !"),
          backgroundColor: Colors.green,
        ),
      );

      _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isApplying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'application : $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allocations = _calculatedAllocations;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF060B26) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Répartition Mensuelle (Virements)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SECTION 1: LIQUIDITÉS & CHARGES ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _glassDecoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "1. Liquidités & Charges",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          "Argent liquide disponible (Somme CCP)",
                          _totalLiquidityController,
                        ),
                        const SizedBox(height: 12),
                        _buildField("Dépenses fixes (Budget)", _fixedExpensesController),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- SECTION 2: OBJECTIFS DE VIREMENT ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _glassDecoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "2. Comptes cibles & Objectifs",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _addAccountTargetDialog,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text("Ajouter"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._targets.map(
                          (target) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    target.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: TextEditingController(
                                      text: target.value
                                          .toStringAsFixed(target.type == AllocationType.fixedAmount ? 2 : 0)
                                          .replaceAll('.', ','),
                                    )..selection = TextSelection.fromPosition(
                                        TextPosition(
                                          offset: target.value
                                              .toStringAsFixed(
                                                  target.type == AllocationType.fixedAmount ? 2 : 0)
                                              .length,
                                        ),
                                      ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(decimal: true),
                                    onChanged: (val) {
                                      setState(() {
                                        target.value =
                                            double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      suffixText:
                                          target.type == AllocationType.fixedAmount ? "€" : "%",
                                      isDense: true,
                                      filled: true,
                                      fillColor: isDark
                                          ? Colors.white.withValues(alpha: 0.03)
                                          : Colors.black.withValues(alpha: 0.02),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                                if (!target.isSystem)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _targets.remove(target);
                                      });
                                    },
                                  )
                                else
                                  const SizedBox(width: 48),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- SECTION 3: SYNTHÈSE & BOUTON APPLIQUER ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorBlue.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colorBlue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "3. Synthèse & Application",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: colorBlue,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildResultRow("Argent liquide disponible", _currency.format(_totalLiquidity)),
                        _buildResultRow("Dépenses fixes", _currency.format(_fixedExpenses)),
                        _buildResultRow("Restant après dépenses fixes", _currency.format(_remainingAfterExpenses)),
                        const Divider(height: 24, thickness: 1.5),
                        // Afficher TOUTES les cibles (CCP en lecture seule fixe, et les autres calculées dynamiquement)
                        ..._targets.map(
                          (target) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: _buildResultRow(
                              target.isSystem ? target.name : "🎯 ${target.name}",
                              _currency.format(allocations[target.id] ?? 0.0),
                              isHighlighted: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            onPressed: _isApplying ? null : _applyAllocation,
                            icon: _isApplying
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, size: 20),
                            label: const Text(
                              "APPLIQUER CETTE RÉPARTITION",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
          fontSize: 13,
        ),
        suffixText: "€",
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildResultRow(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlighted ? 15 : 14,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlighted ? 16 : 14,
              fontWeight: FontWeight.w900,
              color: isHighlighted
                  ? colorBlue
                  : (isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _glassDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
      ),
    );
  }
}
