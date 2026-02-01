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

  final SavingsAccountService _service = SavingsAccountService();

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

  void _checkChanges() {
    final principal =
    double.tryParse(_principalController.text.replaceAll(',', '.'));
    final interest =
    double.tryParse(_interestController.text.replaceAll(',', '.'));

    if (principal == null || interest == null) return;

    setState(() {
      _currentPrincipal = principal;
      _currentInterest = interest;
      _hasChanges =
          principal != _initialPrincipal || interest != _initialInterest;
    });
  }

  Future<void> _saveChanges() async {
    if (widget.account.ceiling != null &&
        _currentPrincipal > widget.account.ceiling!) {
      _showPopup(
        'Erreur',
        'Le capital dépasse le plafond autorisé.',
      );
      return;
    }

    final success = await _service.updateSavingsAccount(
      savingsAccountId: widget.account.id,
      principal: _currentPrincipal,
      interest: _currentInterest,
    );

    if (!mounted) return;

    if (!success) {
      _showPopup('Erreur', 'Impossible de sauvegarder les modifications.');
      return;
    }

    widget.account.principal = _currentPrincipal;
    widget.account.interest = _currentInterest;

    Navigator.of(context).pop(widget.account);
  }

  void _showPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content:
        Text(message, style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  double get _fillPercentage {
    if (widget.account.ceiling == null || widget.account.ceiling == 0) return 0;
    return (_currentPrincipal / widget.account.ceiling!) * 100;
  }

  Color get _fillColor {
    if (_fillPercentage >= 80) return Colors.redAccent;
    if (_fillPercentage >= 60) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final percent = NumberFormat.decimalPattern('fr_FR');

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(widget.account);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: _buildAppBar(),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0F172A),
                Colors.blue.shade900.withValues(alpha: 0.35),
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildInfoSection(currency, percent),
                const SizedBox(height: 20),
                _buildEditableSection(),
                const SizedBox(height: 20),
                _buildTotalSection(currency),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= UI =================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: const BackButton(color: Colors.white),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.account.sourceName,
              style: const TextStyle(color: Colors.white, fontSize: 18)),
          Text(widget.account.bankName,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
        ],
      ),
      actions: [
        if (_hasChanges)
          IconButton(
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            onPressed: _saveChanges,
          )
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _bankLogo(),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.account.bankName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Text(widget.account.sourceName,
                  style:
                  TextStyle(color: Colors.white.withValues(alpha: 0.6))),
            ],
          )
        ],
      ),
    );
  }

  Widget _bankLogo() {
    return Container(
      width: 46,
      height: 46,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300.withValues(alpha: 0.3)),
      ),
      child: widget.account.logoUrl.isEmpty
          ? Icon(Icons.account_balance,
          color: Colors.blue.shade300, size: 26)
          : ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(widget.account.logoUrl),
      ),
    );
  }

  Widget _buildInfoSection(
      NumberFormat currency, NumberFormat percent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.info_outline, 'Informations'),
          const SizedBox(height: 16),
          if (widget.account.interestRate != null)
            _infoRow(
              "Taux d'intérêt",
              "${percent.format(widget.account.interestRate! * 100)} %",
            ),
          if (widget.account.ceiling != null) ...[
            const SizedBox(height: 12),
            _infoRow("Plafond", currency.format(widget.account.ceiling)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _fillPercentage / 100,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(_fillColor),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildEditableSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.edit, 'Montants éditables'),
          const SizedBox(height: 16),
          _field(_principalController, 'Capital'),
          const SizedBox(height: 12),
          _field(_interestController, 'Intérêts acquis'),
        ],
      ),
    );
  }

  Widget _buildTotalSection(NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(currency.format(_currentPrincipal + _currentInterest),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
        TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        suffixText: '€',
        suffixStyle:
        TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade300, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
            TextStyle(color: Colors.white.withValues(alpha: 0.6))),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.blue.shade900.withValues(alpha: 0.25),
          Colors.blue.shade800.withValues(alpha: 0.15),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border:
      Border.all(color: Colors.blue.shade400.withValues(alpha: 0.3)),
    );
  }
}
