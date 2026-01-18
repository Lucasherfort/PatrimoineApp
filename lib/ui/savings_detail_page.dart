import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/savings/user_savings_account_view.dart';

class SavingsDetailPage extends StatefulWidget {
  final UserSavingsAccountView account;
  final void Function(double newPrincipal, double newInterest)? onUpdate;

  const SavingsDetailPage({
    super.key,
    required this.account,
    this.onUpdate,
  });

  @override
  State<SavingsDetailPage> createState() => _SavingsDetailPageState();
}

class _SavingsDetailPageState extends State<SavingsDetailPage> {
  late TextEditingController _principalController;
  late TextEditingController _interestController;

  @override
  void initState() {
    super.initState();
    _principalController = TextEditingController(
      text: widget.account.principal.toStringAsFixed(2).replaceAll('.', ','),
    );
    _interestController = TextEditingController(
      text: widget.account.interest.toStringAsFixed(2).replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _principalController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final principal = double.tryParse(
      _principalController.text.replaceAll(',', '.'),
    );
    final interest = double.tryParse(
      _interestController.text.replaceAll(',', '.'),
    );

    if (principal == null || interest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montants invalides')),
      );
      return;
    }

    if (widget.onUpdate != null) {
      widget.onUpdate!(principal, interest);
      Navigator.pop(context);
    }
  }

  double get _fillPercentage {
    if (widget.account.ceiling == null || widget.account.ceiling == 0) {
      return 0;
    }
    return (widget.account.principal / widget.account.ceiling!) * 100;
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
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
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveChanges,
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banque + logo
            _buildHeader(),

            const SizedBox(height: 24),

            // SECTION 1 : Informations non éditables
            _buildInfoSection(currency, percentFormat),

            const SizedBox(height: 24),

            // SECTION 2 : Montants éditables
            _buildEditableSection(currency),

            const SizedBox(height: 24),

            // Total
            _buildTotalSection(currency),
          ],
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
              ? Icon(
            Icons.account_balance,
            color: Colors.blue.shade700,
          )
              : ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              widget.account.logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.account_balance,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.account.bankName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.account.sourceName,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
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
              const Text(
                'Informations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Taux d'intérêt
          if (widget.account.interestRate != null)
            _InfoRow(
              label: "Taux d'intérêt",
              value: "${percentFormat.format(widget.account.interestRate! * 100)} %",
            ),

          // Plafond
          if (widget.account.ceiling != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              label: "Plafond",
              value: currency.format(widget.account.ceiling),
            ),

            // Barre de progression du plafond
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remplissage',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${_fillPercentage.toStringAsFixed(1)} %',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _fillColor,
                      ),
                    ),
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
                if (_fillPercentage >= 80)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 16, color: Colors.red.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Plafond bientôt atteint',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
              const Text(
                'Montants éditables',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Capital
          TextField(
            controller: _principalController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Capital',
              suffixText: '€',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Intérêts acquis
          TextField(
            controller: _interestController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Intérêts acquis',
              suffixText: '€',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(NumberFormat currency) {
    final currentPrincipal = double.tryParse(
      _principalController.text.replaceAll(',', '.'),
    ) ??
        widget.account.principal;
    final currentInterest = double.tryParse(
      _interestController.text.replaceAll(',', '.'),
    ) ??
        widget.account.interest;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            currency.format(currentPrincipal + currentInterest),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}