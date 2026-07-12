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
  // --- Palette de couleurs ---
  static const Color colorDarkBg = Color(0xFF060B26);
  static const Color colorBlueMain = Color(0xFF0D71EE);
  static const Color colorGreenFlash = Color(0xFF65E046);
  static const Color colorGreenDark = Color(0xFF15803D);

  late TextEditingController _principalController;
  late TextEditingController _interestController;

  late double _currentPrincipal;
  late double _currentInterest;
  late bool _automaticCalculation;

  bool _hasChanges = false;
  final SavingsAccountService _service = SavingsAccountService();

  @override
  void initState() {
    super.initState();
    _currentPrincipal = widget.account.principal;
    _currentInterest = widget.account.interest;
    _automaticCalculation = widget.account.automaticInterestCalculation;

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
    final p = double.tryParse(_principalController.text.replaceAll(',', '.'));
    final i = double.tryParse(_interestController.text.replaceAll(',', '.'));

    if (p == null || i == null) return;

    setState(() {
      _currentPrincipal = p;
      _currentInterest = i;
      _hasChanges =
          p != widget.account.principal ||
          i != widget.account.interest ||
          _automaticCalculation != widget.account.automaticInterestCalculation;
    });
  }

  double get _fillPercentage =>
      (widget.account.ceiling != null && widget.account.ceiling! > 0)
      ? (_currentPrincipal / widget.account.ceiling!)
      : 0.0;

  Future<void> _saveChanges() async {
    if (widget.account.ceiling != null &&
        _currentPrincipal > widget.account.ceiling!) {
      _showError('Le capital dépasse le plafond autorisé.');
      return;
    }

    final success = await _service.updateSavingsAccount(
      savingsAccountId: widget.account.id,
      principal: _currentPrincipal,
      interest: _currentInterest,
      automaticInterestCalculation: _automaticCalculation,
    );

    if (!mounted) return;

    if (!success) {
      _showError('Impossible de sauvegarder les modifications.');
      return;
    }

    widget.account.principal = _currentPrincipal;
    widget.account.interest = _currentInterest;
    widget.account.automaticInterestCalculation = _automaticCalculation;

    Navigator.of(context).pop(widget.account);
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

    return Scaffold(
      backgroundColor: isDark ? colorDarkBg : const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // Effet de halo lumineux en arrière-plan
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
                  _buildAutoCalcToggle(context),
                  const SizedBox(height: 120), // Espace pour le bouton flottant
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _hasChanges ? _buildSaveButton() : null,
    );
  }

  // --- Header : Épargne Totale & Badges ---
  Widget _buildMainBalance(BuildContext context, NumberFormat currency) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentFormat = NumberFormat.decimalPattern('fr_FR');

    return Column(
      children: [
        Text(
          "ÉPARGNE TOTALE",
          style: TextStyle(
            color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          currency.format(_currentPrincipal + _currentInterest),
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
                    "${percentFormat.format(widget.account.interestRate! * 100)} %",
                color: isDark ? colorGreenFlash : colorGreenDark,
                opacity: 0.15,
                hasBorder: true,
              ),
          ],
        ),
      ],
    );
  }

  // --- Section Plafond ---
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
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
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
                  color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black45,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Card Edition ---
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
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
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

  Widget _buildElegantField(
    BuildContext context,
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
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
            color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black45,
            fontSize: 14,
          ),
          suffixText: "€",
          suffixStyle: TextStyle(
            color: isDark ? Colors.white24 : Colors.black26,
            fontWeight: FontWeight.bold,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // --- Toggle Switch ---
  Widget _buildAutoCalcToggle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: _glassDecoration(context),
      child: SwitchListTile(
        value: _automaticCalculation,
        activeThumbColor: isDark ? colorGreenFlash : colorGreenDark,
        activeTrackColor: (isDark ? colorGreenFlash : colorGreenDark).withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          "Calculateur intelligent",
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Précision basée sur les quinzaines",
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
        ),
        onChanged: (v) => setState(() {
          _automaticCalculation = v;
          _checkChanges();
        }),
      ),
    );
  }

  // --- Widgets Utilitaires ---
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: BackButton(color: isDark ? Colors.white : Colors.black87),
      centerTitle: true,
      title: Text(
        widget.account.sourceName,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
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

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorBlueMain,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            shadowColor: colorBlueMain.withValues(alpha: 0.4),
          ),
          onPressed: _saveChanges,
          child: const Text(
            "ENREGISTRER",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _glassDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
      boxShadow: isDark ? null : [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
