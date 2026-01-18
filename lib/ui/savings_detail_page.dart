import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/savings/user_savings_account_view.dart';
import '../services/savings_account_service.dart';

class SavingsDetailPage extends StatefulWidget {
  final UserSavingsAccountView account;

  const SavingsDetailPage({super.key, required this.account});

  @override
  State<SavingsDetailPage> createState() => _SavingsDetailPageState();
}

class _SavingsDetailPageState extends State<SavingsDetailPage> {
  late TextEditingController _principalController;
  late TextEditingController _interestController;
  late double _initialPrincipal;
  late double _initialInterest;
  late double _currentPrincipal;
  late double _currentInterest;
  bool _hasChanges = false;

  final SavingsAccountService _savingsAccountService = SavingsAccountService();

  @override
  void initState() {
    super.initState();

    _initialPrincipal = widget.account.principal;
    _initialInterest = widget.account.interest;
    _currentPrincipal = _initialPrincipal;
    _currentInterest = _initialInterest;

    _principalController = TextEditingController(
      text: _currentPrincipal.toStringAsFixed(2).replaceAll('.', ','),
    );
    _interestController = TextEditingController(
      text: _currentInterest.toStringAsFixed(2).replaceAll('.', ','),
    );

    _principalController.addListener(_checkChanges);
    _interestController.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _principalController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    // Vérification plafond
    if (widget.account.ceiling != null && _currentPrincipal > widget.account.ceiling!) {
      if (!mounted) return;
      _showPopup(
        'Erreur',
        'Le capital ne peut pas dépasser le plafond de ${widget.account.ceiling!.toStringAsFixed(2)} €.',
      );
      return;
    }

    final success = await _savingsAccountService.updateSavingsAccount(
      savingsAccountId: widget.account.id,
      principal: _currentPrincipal,
      interest: _currentInterest,
    );

    if (!mounted) return; // 🔥 protection contre la destruction du widget pendant l'await

    if (!success) {
      _showPopup('Erreur', 'Impossible de sauvegarder les modifications.');
      return;
    }

    // 🔥 Met à jour l'objet existant
    widget.account.principal = _currentPrincipal;
    widget.account.interest = _currentInterest;

    _hasChanges = false;

    // Retourner l'objet mis à jour au parent
    Navigator.of(context).pop(widget.account);
  }

  void _checkChanges() {
    final principal = double.tryParse(_principalController.text.replaceAll(',', '.'));
    final interest = double.tryParse(_interestController.text.replaceAll(',', '.'));

    if (principal == null || interest == null) return;

    setState(() {
      _currentPrincipal = principal;
      _currentInterest = interest;
      _hasChanges = principal != _initialPrincipal || interest != _initialInterest;
    });
  }

  void _showPopup(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  double get _fillPercentage {
    if (widget.account.ceiling == null || widget.account.ceiling == 0) return 0;
    return (_currentPrincipal / widget.account.ceiling!) * 100;
  }

  Color get _fillColor {
    if (_fillPercentage >= 80) return Colors.red;
    if (_fillPercentage >= 60) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final percentFormat = NumberFormat.decimalPattern('fr_FR');

    return PopScope(
      canPop: !_hasChanges, // bloque le pop automatique si modifié
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_hasChanges) {
          widget.account.principal = _currentPrincipal;
          widget.account.interest = _currentInterest;

          Navigator.of(context).pop(widget.account);
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_hasChanges) {
                widget.account.principal = _currentPrincipal;
                widget.account.interest = _currentInterest;
                Navigator.of(context).pop(widget.account);
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.account.sourceName,
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                widget.account.bankName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          actions: [
            if (_hasChanges)
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Enregistrer',
                onPressed: _saveChanges,
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildInfoSection(currency, percentFormat),
              const SizedBox(height: 24),
              _buildEditableSection(currency),
              const SizedBox(height: 24),
              _buildTotalSection(currency),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: widget.account.logoUrl.isEmpty
              ? Icon(Icons.account_balance, color: Colors.blue.shade700)
              : ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              widget.account.logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(Icons.account_balance, color: Colors.blue.shade700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.account.bankName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.account.sourceName, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection(NumberFormat currency, NumberFormat percentFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text('Informations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.account.interestRate != null)
            _InfoRow(
              label: "Taux d'intérêt",
              value: "${percentFormat.format(widget.account.interestRate! * 100)} %",
            ),
          if (widget.account.ceiling != null) ...[
            const SizedBox(height: 12),
            _InfoRow(label: "Plafond", value: currency.format(widget.account.ceiling)),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Remplissage', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    Text('${_fillPercentage.toStringAsFixed(1)} %',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _fillColor)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _fillPercentage / 100,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(_fillColor),
                  ),
                ),
                const SizedBox(height: 8),
                if (_fillPercentage >= 100)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange.shade800),
                        const SizedBox(width: 4),
                        Text('Vous avez atteint le plafond',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.orange.shade800)),
                      ],
                    ),
                  )
                else if (_fillPercentage >= 80)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red.shade700),
                        const SizedBox(width: 4),
                        Text('Plafond bientôt atteint',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.red.shade700)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditableSection(NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text('Montants éditables', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _principalController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Capital',
              suffixText: '€',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _interestController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Intérêts acquis',
              suffixText: '€',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(currency.format(_currentPrincipal + _currentInterest),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
