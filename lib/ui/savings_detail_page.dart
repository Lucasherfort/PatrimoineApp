import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/liquidity/user_liquidity_account_view.dart';
import '../../models/savings/user_savings_account_view.dart';
import '../services/liquidity_service.dart';
import '../services/savings_account_service.dart';

class SavingsDetailPage extends StatefulWidget {
  final UserSavingsAccountView account;

  const SavingsDetailPage({super.key, required this.account});

  @override
  State<SavingsDetailPage> createState() => _SavingsDetailPageState();
}

class _SavingsDetailPageState extends State<SavingsDetailPage> {
  // --- Palette de couleurs ---
  static const Color colorDarkBg = Color(0xFF060B26);
  static const Color colorBlueMain = Color(0xFF0D71EE);
  static const Color colorGreenFlash = Color(0xFF65E046);
  static const Color colorGreenDark = Color(0xFF15803D);

  late TextEditingController _principalController;
  late TextEditingController _interestController;
  late TextEditingController _transferAmountController;

  late double _currentPrincipal;
  late double _currentInterest;

  late double _lastSavedPrincipal;
  late double _lastSavedInterest;

  bool _hasChanges = false;
  bool _hasSavedAtLeastOnce = false;
  bool _isLoadingLiquidity = true;
  bool _isTransferring = false;

  final SavingsAccountService _service = SavingsAccountService();
  final LiquidityService _liquidityService = LiquidityService();

  List<UserLiquidityAccountView> _liquidityAccounts = [];
  UserLiquidityAccountView? _selectedLiquidityAccount;

  @override
  void initState() {
    super.initState();
    _currentPrincipal = widget.account.principal;
    _currentInterest = widget.account.interest;

    _lastSavedPrincipal = widget.account.principal;
    _lastSavedInterest = widget.account.interest;

    _principalController = TextEditingController(
      text: _currentPrincipal.toStringAsFixed(2).replaceAll('.', ','),
    );

    _interestController = TextEditingController(
      text: _currentInterest.toStringAsFixed(2).replaceAll('.', ','),
    );

    _transferAmountController = TextEditingController(
      text: _currentPrincipal.toStringAsFixed(2).replaceAll('.', ','),
    );

    _principalController.addListener(_checkChanges);
    _interestController.addListener(_checkChanges);
    _fetchLiquidityAccounts();
  }

  @override
  void dispose() {
    _principalController.dispose();
    _interestController.dispose();
    _transferAmountController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiquidityAccounts() async {
    try {
      final accounts = await _liquidityService.getUserLiquidityAccounts();
      if (!mounted) return;
      setState(() {
        _liquidityAccounts = accounts;
        _isLoadingLiquidity = false;
        if (accounts.isNotEmpty) {
          _selectedLiquidityAccount = accounts.firstWhere(
            (a) =>
                a.sourceName.toLowerCase().contains('ccp') ||
                a.sourceName.toLowerCase().contains('courant') ||
                a.sourceName.toLowerCase().contains('chèque'),
            orElse: () => accounts.first,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLiquidity = false;
      });
    }
  }

  void _checkChanges() {
    final p = double.tryParse(_principalController.text.replaceAll(',', '.'));
    final i = double.tryParse(_interestController.text.replaceAll(',', '.'));

    if (p == null || i == null) return;

    setState(() {
      _currentPrincipal = p;
      _currentInterest = i;
      _hasChanges = p != _lastSavedPrincipal || i != _lastSavedInterest;
    });
  }

  double get _fillPercentage =>
      (widget.account.ceiling != null && widget.account.ceiling! > 0)
          ? (_currentPrincipal / widget.account.ceiling!)
          : 0.0;

  Future<bool> _saveChangesInline() async {
    if (widget.account.ceiling != null &&
        _currentPrincipal > widget.account.ceiling!) {
      _showError('Le capital dépasse le plafond autorisé.');
      return false;
    }

    final success = await _service.updateSavingsAccount(
      savingsAccountId: widget.account.id,
      principal: _currentPrincipal,
      interest: _currentInterest,
      automaticInterestCalculation: false,
    );

    if (!mounted) return false;

    if (!success) {
      _showError('Impossible de sauvegarder les modifications.');
      return false;
    }

    widget.account.principal = _currentPrincipal;
    widget.account.interest = _currentInterest;

    _lastSavedPrincipal = _currentPrincipal;
    _lastSavedInterest = _currentInterest;
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

  Future<void> _performTransfer() async {
    if (_selectedLiquidityAccount == null) return;

    final transferAmount = double.tryParse(
            _transferAmountController.text.replaceAll(',', '.')) ??
        0.0;

    if (transferAmount <= 0) {
      _showError('Veuillez entrer un montant valide supérieur à 0 €');
      return;
    }

    if (transferAmount > _currentPrincipal) {
      _showError('Le montant du virement dépasse le capital déposé.');
      return;
    }

    final currency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmer le virement'),
        content: Text(
          'Voulez-vous vraiment transférer ${currency.format(transferAmount)} depuis le capital de ce compte vers le compte CCP (${_selectedLiquidityAccount!.sourceName}) ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorBlueMain,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isTransferring = true);

    try {
      // 1. Créditer le compte CCP
      final newCcpAmount = _selectedLiquidityAccount!.amount + transferAmount;
      await _liquidityService.updateAmount(
        accountId: _selectedLiquidityAccount!.id,
        amount: newCcpAmount,
      );

      // 2. Déduire le montant du capital déposé (principal)
      final newPrincipal = _currentPrincipal - transferAmount;
      final success = await _service.updateSavingsAccount(
        savingsAccountId: widget.account.id,
        principal: newPrincipal,
        interest: _currentInterest,
        automaticInterestCalculation: false,
      );

      if (!mounted) return;

      if (!success) {
        _showError('Erreur lors de la mise à jour du compte épargne.');
        setState(() => _isTransferring = false);
        return;
      }

      // Mettre à jour l'état local
      widget.account.principal = newPrincipal;
      _currentPrincipal = newPrincipal;
      _lastSavedPrincipal = newPrincipal;
      _principalController.text =
          newPrincipal.toStringAsFixed(2).replaceAll('.', ',');
      _transferAmountController.text =
          newPrincipal.toStringAsFixed(2).replaceAll('.', ',');

      _hasSavedAtLeastOnce = true;

      setState(() {
        _hasChanges = false;
        _isTransferring = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Virement de ${currency.format(transferAmount)} effectué vers le CCP.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      _fetchLiquidityAccounts();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showUnsavedChangesDialog(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context)
              .pop(_hasSavedAtLeastOnce ? widget.account : null);
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
                    _buildProgressSection(context, currency),
                    const SizedBox(height: 24),
                    _buildEditableCard(context),
                    const SizedBox(height: 24),
                    _buildTransferSection(context, currency),
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
    final displayValue = _currentPrincipal + _currentInterest;

    return Column(
      children: [
        Text(
          "ÉPARGNE TOTALE",
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
          currency.format(displayValue),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBadge(
              icon: Icons.account_balance,
              label: widget.account.bankName,
              color: isDark ? Colors.white : Colors.black87,
              opacity: isDark ? 0.1 : 0.05,
            ),
            const SizedBox(width: 10),
            if (widget.account.interestRate != null)
              _buildBadge(
                icon: Icons.show_chart,
                label:
                    "${NumberFormat.decimalPattern('fr_FR').format(widget.account.interestRate! * 100)} %",
                color: isDark ? colorGreenFlash : colorGreenDark,
                opacity: 0.15,
                hasBorder: true,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context, NumberFormat currency) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glassDecoration(context),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Utilisation du plafond",
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "${(_fillPercentage * 100).toStringAsFixed(1)}%",
                style: const TextStyle(
                  color: colorBlueMain,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _fillPercentage,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation(
                _fillPercentage > 0.9 ? Colors.redAccent : colorBlueMain,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currency.format(_currentPrincipal),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                widget.account.ceiling != null
                    ? currency.format(widget.account.ceiling)
                    : "Sans plafond",
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black45,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: _glassDecoration(context),
      child: Column(
        children: [
          _buildElegantField(
            context,
            _principalController,
            "Capital déposé",
            Icons.account_balance_wallet_outlined,
          ),
          Divider(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
          _buildElegantField(
            context,
            _interestController,
            "Intérêts cumulés",
            Icons.add_chart_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTransferSection(BuildContext context, NumberFormat currency) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glassDecoration(context),
      child: Column(
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
              Expanded(
                child: Text(
                  "Virement vers le CCP",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingLiquidity)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_liquidityAccounts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Colors.amber.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Aucun compte CCP (liquidités) disponible pour recevoir un virement.",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (_liquidityAccounts.length > 1) ...[
              Text(
                "Compte CCP destinataire",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<UserLiquidityAccountView>(
                initialValue: _selectedLiquidityAccount,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.02),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                dropdownColor:
                    isDark ? const Color(0xFF1E293B) : Colors.white,
                items: _liquidityAccounts.map((account) {
                  return DropdownMenuItem<UserLiquidityAccountView>(
                    value: account,
                    child: Text(
                      "${account.sourceName} - ${account.bankName} (${currency.format(account.amount)})",
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedLiquidityAccount = val);
                  }
                },
              ),
              const SizedBox(height: 16),
            ] else if (_selectedLiquidityAccount != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "${_selectedLiquidityAccount!.sourceName} (${_selectedLiquidityAccount!.bankName})",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      currency.format(_selectedLiquidityAccount!.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text(
              "Montant à transférer depuis le capital (€)",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _transferAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                suffixText: "€",
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

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
                  elevation: 4,
                ),
                onPressed: _isTransferring ? null : _performTransfer,
                icon: _isTransferring
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
                  "TRANSFÉRER SUR LE CCP",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildElegantField(
    BuildContext context,
    TextEditingController controller,
    String label,
    IconData icon, {
    String suffix = "€",
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        decoration: InputDecoration(
          icon: Icon(
            icon,
            color: colorBlueMain.withValues(alpha: 0.4),
            size: 22,
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.black45,
            fontSize: 14,
          ),
          suffixText: suffix,
          suffixStyle: TextStyle(
            color: isDark ? Colors.white24 : Colors.black26,
            fontWeight: FontWeight.bold,
          ),
          border: InputBorder.none,
        ),
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
              Navigator.of(context)
                  .pop(_hasSavedAtLeastOnce ? widget.account : null);
            }
          } else {
            Navigator.of(context)
                .pop(_hasSavedAtLeastOnce ? widget.account : null);
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
    bool hasBorder = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(14),
        border: hasBorder
            ? Border.all(color: color.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
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
