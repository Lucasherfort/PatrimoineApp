import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/investments/user_investment_account_view.dart';
import '../models/liquidity/user_liquidity_account_view.dart';
import '../models/savings/user_savings_account_view.dart';
import '../services/investment_service.dart';
import '../services/liquidity_service.dart';
import '../services/savings_account_service.dart';

enum DestinationAccountType { liquidity, savings, pea }

class TransferDestinationAccount {
  final int id;
  final String label;
  final String bankName;
  final DestinationAccountType type;
  final double currentBalance;
  final dynamic rawAccount;

  TransferDestinationAccount({
    required this.id,
    required this.label,
    required this.bankName,
    required this.type,
    required this.currentBalance,
    required this.rawAccount,
  });

  String get typeLabel {
    switch (type) {
      case DestinationAccountType.liquidity:
        return 'Compte Courant';
      case DestinationAccountType.savings:
        return 'Épargne';
      case DestinationAccountType.pea:
        return 'PEA (Espèces)';
    }
  }

  IconData get icon {
    switch (type) {
      case DestinationAccountType.liquidity:
        return Icons.euro_rounded;
      case DestinationAccountType.savings:
        return Icons.savings_rounded;
      case DestinationAccountType.pea:
        return Icons.show_chart_rounded;
    }
  }
}

class LiquidityDetailPage extends StatefulWidget {
  final UserLiquidityAccountView account;

  const LiquidityDetailPage({super.key, required this.account});

  @override
  State<LiquidityDetailPage> createState() => _LiquidityDetailPageState();
}

class _LiquidityDetailPageState extends State<LiquidityDetailPage> {
  static const Color colorDarkBg = Color(0xFF060B26);
  static const Color colorBlueMain = Color(0xFF0D71EE);

  late TextEditingController _amountController;
  late TextEditingController _transferAmountController;

  late double _currentAmount;
  late double _lastSavedAmount;

  bool _hasChanges = false;
  bool _hasSavedAtLeastOnce = false;
  bool _isLoadingDestinations = true;
  bool _isTransferring = false;

  final LiquidityService _liquidityService = LiquidityService();
  final SavingsAccountService _savingsService = SavingsAccountService();
  final InvestmentService _investmentService = InvestmentService();

  List<TransferDestinationAccount> _destinations = [];
  TransferDestinationAccount? _selectedDestination;

  @override
  void initState() {
    super.initState();
    _currentAmount = widget.account.amount;
    _lastSavedAmount = widget.account.amount;

    _amountController = TextEditingController(
      text: _currentAmount.toStringAsFixed(2).replaceAll('.', ','),
    );

    _transferAmountController = TextEditingController(
      text: _currentAmount.toStringAsFixed(2).replaceAll('.', ','),
    );

    _amountController.addListener(_checkChanges);
    _fetchDestinations();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transferAmountController.dispose();
    super.dispose();
  }

  Future<void> _fetchDestinations() async {
    try {
      final List<TransferDestinationAccount> list = [];

      // 1. Autres comptes courants
      final liquidities = await _liquidityService.getUserLiquidityAccounts();
      for (final acc in liquidities) {
        if (acc.id != widget.account.id) {
          list.add(
            TransferDestinationAccount(
              id: acc.id,
              label: acc.sourceName,
              bankName: acc.bankName,
              type: DestinationAccountType.liquidity,
              currentBalance: acc.amount,
              rawAccount: acc,
            ),
          );
        }
      }

      // 2. Comptes épargne
      final savings = await _savingsService.getUserSavingsAccounts();
      for (final acc in savings) {
        list.add(
          TransferDestinationAccount(
            id: acc.id,
            label: acc.sourceName,
            bankName: acc.bankName,
            type: DestinationAccountType.savings,
            currentBalance: acc.principal,
            rawAccount: acc,
          ),
        );
      }

      // 3. Comptes investissement de type PEA
      final investments = await _investmentService
          .getInvestmentAccountsForUserWithPrices();
      for (final acc in investments) {
        if (acc.sourceName.toUpperCase().contains('PEA')) {
          list.add(
            TransferDestinationAccount(
              id: acc.id,
              label: acc.sourceName,
              bankName: acc.bankName,
              type: DestinationAccountType.pea,
              currentBalance: acc.cashBalance,
              rawAccount: acc,
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _destinations = list;
        _isLoadingDestinations = false;
        if (list.isNotEmpty) {
          if (_selectedDestination == null) {
            _selectedDestination = list.first;
          } else {
            _selectedDestination = list.firstWhere(
              (d) =>
                  d.id == _selectedDestination!.id &&
                  d.type == _selectedDestination!.type,
              orElse: () => list.first,
            );
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingDestinations = false;
      });
    }
  }

  void _checkChanges() {
    final a = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (a == null) return;

    setState(() {
      _currentAmount = a;
      _hasChanges = a != _lastSavedAmount;
    });
  }

  Future<bool> _saveChangesInline() async {
    try {
      await _liquidityService.updateAmount(
        accountId: widget.account.id,
        amount: _currentAmount,
      );

      if (!mounted) return false;

      widget.account.amount = _currentAmount;
      _lastSavedAmount = _currentAmount;
      _hasSavedAtLeastOnce = true;

      setState(() {
        _hasChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modifications enregistrées'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      return true;
    } catch (e) {
      if (!mounted) return false;
      _showError('Erreur lors de la sauvegarde : $e');
      return false;
    }
  }

  Future<bool> _showUnsavedChangesDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Enregistrer les modifications ?'),
        content: const Text(
          'Vous avez des modifications non enregistrées. Voulez-vous les enregistrer avant de quitter ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Ne pas enregistrer'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorBlueMain,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      return await _saveChangesInline();
    } else if (result == 'discard') {
      return true;
    }
    return false;
  }

  void _openTransferModal(BuildContext context) {
    final transferController = TextEditingController(
      text: _currentAmount.toStringAsFixed(2).replaceAll('.', ','),
    );
    bool isTransferringModal = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorBlueMain.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          color: colorBlueMain,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        "Virement vers un autre compte",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_isLoadingDestinations)
                    const Center(child: CircularProgressIndicator())
                  else if (_destinations.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        "Aucun autre compte disponible pour effectuer un virement.",
                        style: TextStyle(fontSize: 13),
                      ),
                    )
                  else ...[
                    const Text(
                      "Compte destinataire",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<TransferDestinationAccount>(
                      initialValue: _selectedDestination,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _destinations.map((dest) {
                        return DropdownMenuItem<TransferDestinationAccount>(
                          value: dest,
                          child: Row(
                            children: [
                              Icon(
                                dest.icon,
                                size: 18,
                                color: isDark ? Colors.amber.shade300 : colorBlueMain,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "${dest.label} (${dest.bankName})",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => _selectedDestination = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Montant à transférer (€)",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: transferController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      decoration: InputDecoration(
                        suffixText: "€",
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorBlueMain,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: isTransferringModalLoading(isTransferringModal)
                            ? null
                            : () async {
                                final amount = double.tryParse(
                                      transferController.text.replaceAll(',', '.'),
                                    ) ??
                                    0.0;
                                if (amount <= 0 || amount > _currentAmount) {
                                  _showError("Montant invalide ou supérieur au solde.");
                                  return;
                                }

                                setModalState(() => isTransferringModal = true);
                                Navigator.pop(context);
                                await _executeTransferModal(amount);
                              },
                        icon: const Icon(Icons.send_rounded, size: 20),
                        label: const Text(
                          "EFFECTUER LE VIREMENT",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool isTransferringModalLoading(bool val) => val || _isTransferring;

  Future<void> _executeTransferModal(double transferAmount) async {
    _transferAmountController.text = transferAmount.toStringAsFixed(2).replaceAll('.', ',');
    await _performTransfer();
  }

  Future<void> _performTransfer() async {
    if (_selectedDestination == null) return;

    final transferAmount =
        double.tryParse(_transferAmountController.text.replaceAll(',', '.')) ??
        0.0;

    if (transferAmount <= 0) {
      _showError('Veuillez entrer un montant valide supérieur à 0 €');
      return;
    }

    if (transferAmount > _currentAmount) {
      _showError('Le montant du virement dépasse le solde disponible.');
      return;
    }

    final currency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final dest = _selectedDestination!;

    setState(() => _isTransferring = true);

    try {
      // 1. Déduire du solde source
      final newSourceAmount = _currentAmount - transferAmount;
      await _liquidityService.updateAmount(
        accountId: widget.account.id,
        amount: newSourceAmount,
      );

      // 2. Créditer la destination
      if (dest.type == DestinationAccountType.liquidity) {
        final target = dest.rawAccount as UserLiquidityAccountView;
        final newTargetAmount = target.amount + transferAmount;
        await _liquidityService.updateAmount(
          accountId: target.id,
          amount: newTargetAmount,
        );
      } else if (dest.type == DestinationAccountType.savings) {
        final target = dest.rawAccount as UserSavingsAccountView;
        final newTargetPrincipal = target.principal + transferAmount;
        await _savingsService.updateSavingsAccount(
          savingsAccountId: target.id,
          principal: newTargetPrincipal,
          interest: target.interest,
          automaticInterestCalculation: false,
        );
      } else if (dest.type == DestinationAccountType.pea) {
        final target = dest.rawAccount as UserInvestmentAccountView;
        final newCashBalance = target.cashBalance + transferAmount;
        await _investmentService.updateInvestmentAccount(
          userInvestmentAccountId: target.id,
          cashBalance: newCashBalance,
          cumulativeDeposits: target.totalContribution + transferAmount,
          openedAt: target.openedAt,
        );
      }

      if (!mounted) return;

      widget.account.amount = newSourceAmount;
      _currentAmount = newSourceAmount;
      _lastSavedAmount = newSourceAmount;
      _amountController.text = newSourceAmount
          .toStringAsFixed(2)
          .replaceAll('.', ',');
      _transferAmountController.text = newSourceAmount
          .toStringAsFixed(2)
          .replaceAll('.', ',');

      _hasSavedAtLeastOnce = true;

      setState(() {
        _hasChanges = false;
        _isTransferring = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Virement de ${currency.format(transferAmount)} effectué vers ${dest.label}.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      _fetchDestinations();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTransferring = false);
      _showError('Erreur lors du virement : $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showUnsavedChangesDialog(context);
        if (shouldPop && context.mounted) {
          Navigator.of(
            context,
          ).pop(_hasSavedAtLeastOnce ? widget.account : null);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? colorDarkBg : const Color(0xFFF8FAFC),
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context),
        body: Stack(
          children: [
            Positioned(
              top: -150,
              left: -50,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorBlueMain.withValues(alpha: isDark ? 0.1 : 0.05),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildMainBalance(context, currency),
                    const SizedBox(height: 40),
                    _buildEditableCard(context),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainBalance(BuildContext context, NumberFormat currency) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          "SOLDE DISPONIBLE",
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.black54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          currency.format(_currentAmount),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 20),
        _buildBadge(
          icon: Icons.account_balance,
          label: "${widget.account.sourceName} - ${widget.account.bankName}",
          color: isDark ? Colors.white : Colors.black87,
          opacity: isDark ? 0.1 : 0.05,
        ),
      ],
    );
  }

  Widget _buildEditableCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glassDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Mettre à jour le solde",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            decoration: InputDecoration(
              suffixText: "€",
              suffixStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontWeight: FontWeight.bold,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.01),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: isDark ? Colors.white : Colors.black87,
        ),
        onPressed: () async {
          if (_hasChanges) {
            final shouldPop = await _showUnsavedChangesDialog(context);
            if (shouldPop && context.mounted) {
              Navigator.of(
                context,
              ).pop(_hasSavedAtLeastOnce ? widget.account : null);
            }
          } else {
            Navigator.of(
              context,
            ).pop(_hasSavedAtLeastOnce ? widget.account : null);
          }
        },
      ),
      centerTitle: true,
      title: Text(
        widget.account.sourceName,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.swap_horiz_rounded,
            color: colorBlueMain,
            size: 24,
          ),
          onPressed: () => _openTransferModal(context),
          tooltip: "Virement vers un autre compte",
        ),
        if (_hasChanges)
          IconButton(
            icon: const Icon(
              Icons.check_rounded,
              color: colorBlueMain,
              size: 28,
            ),
            onPressed: _saveChangesInline,
            tooltip: "Enregistrer les modifications",
          ),
      ],
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    required double opacity,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
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
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
      ),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }
}
