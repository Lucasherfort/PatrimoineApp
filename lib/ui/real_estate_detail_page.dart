import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/liquidity/user_liquidity_account_view.dart';
import '../models/patrimoine/real_estate_asset.dart';
import '../services/liquidity_service.dart';
import '../services/real_estate_service.dart';

class RealEstateDetailPage extends StatefulWidget {
  final RealEstateAsset asset;

  const RealEstateDetailPage({super.key, required this.asset});

  @override
  State<RealEstateDetailPage> createState() => _RealEstateDetailPageState();
}

class _RealEstateDetailPageState extends State<RealEstateDetailPage> {
  late TextEditingController _labelController;
  late TextEditingController _amountController;
  late TextEditingController _transferAmountController;

  late String _currentLabel;
  late double _currentAmount;

  late String _lastSavedLabel;
  late double _lastSavedAmount;

  bool _hasChanges = false;
  bool _hasSavedAtLeastOnce = false;
  bool _closeAccountAfterTransfer = false;
  bool _isLoadingLiquidity = true;
  bool _isTransferring = false;

  final RealEstateService _service = RealEstateService();
  final LiquidityService _liquidityService = LiquidityService();

  List<UserLiquidityAccountView> _liquidityAccounts = [];
  UserLiquidityAccountView? _selectedLiquidityAccount;

  @override
  void initState() {
    super.initState();
    _currentLabel = widget.asset.label;
    _currentAmount = widget.asset.amount;

    _lastSavedLabel = widget.asset.label;
    _lastSavedAmount = widget.asset.amount;

    _labelController = TextEditingController(text: _currentLabel);
    _amountController = TextEditingController(
      text: _currentAmount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _transferAmountController = TextEditingController(
      text: _currentAmount.toStringAsFixed(2).replaceAll('.', ','),
    );

    _labelController.addListener(_checkChanges);
    _amountController.addListener(_checkChanges);
    _fetchLiquidityAccounts();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
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
    final a = double.tryParse(_amountController.text.replaceAll(',', '.'));
    final l = _labelController.text.trim();
    if (a == null) return;

    setState(() {
      _currentAmount = a;
      _currentLabel = l.isNotEmpty ? l : _lastSavedLabel;
      _hasChanges = a != _lastSavedAmount || l != _lastSavedLabel;
      if (_closeAccountAfterTransfer) {
        _transferAmountController.text = a
            .toStringAsFixed(2)
            .replaceAll('.', ',');
      }
    });
  }

  Future<bool> _saveChangesInline() async {
    try {
      await _service.updateAsset(
        assetId: widget.asset.id,
        amount: _currentAmount,
        label: _currentLabel,
      );
      if (!mounted) return false;

      _lastSavedAmount = _currentAmount;
      _lastSavedLabel = _currentLabel;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la sauvegarde'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
              backgroundColor: const Color(0xFF0D71EE),
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

    final transferAmount = _closeAccountAfterTransfer
        ? _currentAmount
        : (double.tryParse(
                _transferAmountController.text.replaceAll(',', '.'),
              ) ??
              0.0);

    if (transferAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un montant valide supérieur à 0 €'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (transferAmount > _currentAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le montant du virement dépasse la valeur du bien.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final currency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmer le virement'),
        content: Text(
          _closeAccountAfterTransfer
              ? 'Voulez-vous vraiment transférer ${currency.format(transferAmount)} sur le compte CCP (${_selectedLiquidityAccount!.sourceName}) et clôturer ce compte immobilier ?'
              : 'Voulez-vous vraiment transférer ${currency.format(transferAmount)} sur le compte CCP (${_selectedLiquidityAccount!.sourceName}) ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D71EE),
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

      if (_closeAccountAfterTransfer) {
        // 2. Clôturer le compte immobilier
        await _service.deleteAsset(widget.asset.id);
      } else {
        // 2. Mettre à jour le solde restant et le libellé du compte
        final newAssetAmount = _currentAmount - transferAmount;
        await _service.updateAsset(
          assetId: widget.asset.id,
          amount: newAssetAmount,
          label: _currentLabel,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _closeAccountAfterTransfer
                ? 'Virement de ${currency.format(transferAmount)} effectué et compte clôturé.'
                : 'Virement de ${currency.format(transferAmount)} effectué.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTransferring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du virement : $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
          Navigator.pop(context, _hasSavedAtLeastOnce);
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF060B26)
            : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_hasChanges) {
                final shouldPop = await _showUnsavedChangesDialog(context);
                if (shouldPop && context.mounted) {
                  Navigator.pop(context, _hasSavedAtLeastOnce);
                }
              } else {
                Navigator.pop(context, _hasSavedAtLeastOnce);
              }
            },
          ),
          title: Text(
            _labelController.text.isNotEmpty
                ? _labelController.text
                : widget.asset.label,
          ),
          centerTitle: true,
          actions: [
            if (_hasChanges)
              IconButton(
                icon: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF0D71EE),
                  size: 28,
                ),
                onPressed: _saveChangesInline,
                tooltip: "Enregistrer les modifications",
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                "VALEUR ESTIMÉE",
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currency.format(_currentAmount),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Card 1: Informations du bien (Nom et Valeur)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: _glassDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Informations du bien",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _labelController,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        labelText: "Nom du compte / bien",
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        prefixIcon: Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: isDark ? Colors.white60 : Colors.black54,
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        labelText: "Valeur estimée",
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        suffixText: "€",
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
              ),

              const SizedBox(height: 24),

              // Card 2: Virement vers le CCP
              _buildTransferSection(context, currency),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransferSection(BuildContext context, NumberFormat currency) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _glassDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D71EE).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: Color(0xFF0D71EE),
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
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.amber.shade700,
                  ),
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
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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

            // Checkbox pour clôturer le compte après le virement
            Theme(
              data: Theme.of(context).copyWith(
                unselectedWidgetColor: isDark ? Colors.white54 : Colors.black45,
              ),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF0D71EE),
                title: Text(
                  "Clôturer le compte après le virement du solde",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                value: _closeAccountAfterTransfer,
                onChanged: (bool? val) {
                  setState(() {
                    _closeAccountAfterTransfer = val ?? false;
                    if (_closeAccountAfterTransfer) {
                      _transferAmountController.text = _currentAmount
                          .toStringAsFixed(2)
                          .replaceAll('.', ',');
                    }
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),

            if (!_closeAccountAfterTransfer) ...[
              const SizedBox(height: 12),
              Text(
                "Montant à transférer (€)",
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
            ],

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D71EE),
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
                label: Text(
                  _closeAccountAfterTransfer
                      ? "TRANSFÉRER LE SOLDE ET CLÔTURER"
                      : "TRANSFÉRER SUR LE CCP",
                  style: const TextStyle(
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
    );
  }
}
