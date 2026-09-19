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
  late TextEditingController _rateController;

  late double _currentPrincipal;
  late double _currentInterest;
  late double? _currentRate;
  DateTime? _openedAt;

  bool _hasChanges = false;
  final SavingsAccountService _service = SavingsAccountService();

  bool get _isPEL => widget.account.sourceName.toUpperCase().contains('PEL');

  @override
  void initState() {
    super.initState();
    _currentPrincipal = widget.account.principal;
    _currentInterest = widget.account.interest;
    _currentRate = widget.account.interestRate;
    _openedAt = widget.account.openedAt;

    _principalController = TextEditingController(
      text: _currentPrincipal.toStringAsFixed(2).replaceAll('.', ','),
    );

    _interestController = TextEditingController(
      text: _currentInterest.toStringAsFixed(2).replaceAll('.', ','),
    );

    _rateController = TextEditingController(
      text: _currentRate != null
          ? (_currentRate! * 100).toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );

    _principalController.addListener(_checkChanges);
    _interestController.addListener(_checkChanges);
    _rateController.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _principalController.dispose();
    _interestController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _checkChanges() {
    final p = double.tryParse(_principalController.text.replaceAll(',', '.'));
    final i = double.tryParse(_interestController.text.replaceAll(',', '.'));
    final rStr = _rateController.text.replaceAll(',', '.');
    final r = double.tryParse(rStr) != null ? double.parse(rStr) / 100 : null;

    if (p == null || i == null) return;

    setState(() {
      _currentPrincipal = p;
      _currentInterest = i;
      _currentRate = r;
      _hasChanges =
          p != widget.account.principal ||
          i != widget.account.interest ||
          r != widget.account.interestRate ||
          _openedAt != widget.account.openedAt;
    });
  }

  // --- LOGIQUE FISCALE PEL ---
  int get _ageInYears {
    if (_openedAt == null) return 0;
    return (DateTime.now().difference(_openedAt!).inDays / 365.25).floor();
  }

  double get _taxRate {
    if (!_isPEL || _openedAt == null) return 0.0;

    final flatTaxDate = DateTime(2018, 1, 1);
    final isAfter2018 =
        _openedAt!.isAfter(flatTaxDate) ||
        _openedAt!.isAtSameMomentAs(flatTaxDate);

    if (isAfter2018) {
      return 0.30; // IR 12.8% + PS 17.2%
    } else if (_ageInYears > 12) {
      return 0.30; // IR 12.8% + PS 17.2% (après 12 ans)
    } else {
      return 0.172; // Uniquement PS 17.2%
    }
  }

  double get _netInterest => _currentInterest * (1 - _taxRate);
  double get _totalNetValue => _currentPrincipal + _netInterest;

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
      automaticInterestCalculation: false,
      interestRate: _currentRate,
      openedAt: _openedAt,
    );

    if (!mounted) return;

    if (!success) {
      _showError('Impossible de sauvegarder les modifications.');
      return;
    }

    widget.account.principal = _currentPrincipal;
    widget.account.interest = _currentInterest;
    widget.account.interestRate = _currentRate;
    widget.account.openedAt = _openedAt;

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
                  if (_isPEL) ...[
                    _buildPELFiscalSelector(context),
                    const SizedBox(height: 24),
                  ],
                  _buildEditableCard(context),
                  const SizedBox(height: 120),
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
        GestureDetector(
          onTap: _isPEL ? () => _showPELInfoPanel(context) : null,
          child: Text(
            currency.format(displayValue),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
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

  Widget _buildPELFiscalSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMMM yyyy', 'fr_FR');

    return Container(
      decoration: _glassDecoration(context),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(
          Icons.calendar_today_rounded,
          color: colorBlueMain.withValues(alpha: 0.6),
          size: 20,
        ),
        title: const Text(
          "Date d'ouverture",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          _openedAt != null
              ? dateFormat.format(_openedAt!)
              : "Cliquer pour définir",
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.edit_calendar_rounded,
          size: 18,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _openedAt ?? DateTime.now(),
            firstDate: DateTime(1980),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setState(() {
              _openedAt = picked;
              _checkChanges();
            });
          }
        },
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
          if (_isPEL) ...[
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
              _rateController,
              "Taux d'intérêt annuel",
              Icons.percent_rounded,
              suffix: "%",
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

  void _showPELInfoPanel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  "Détails fiscaux du PEL",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                if (_openedAt != null)
                  _buildModernInfoCard(
                    label: "Ancienneté du contrat",
                    value: "$_ageInYears ans",
                    icon: Icons.history_rounded,
                  )
                else
                  _buildModernInfoCard(
                    label: "Ancienneté",
                    value: "Date non définie",
                    icon: Icons.history_rounded,
                    textColor: Colors.orange,
                  ),
                const SizedBox(height: 12),
                _buildModernInfoCard(
                  label: "Fiscalité appliquée",
                  value: _openedAt == null
                      ? "N/A"
                      : (_taxRate > 0.172 ? "PFU (30,0%)" : "PS (17,2%)"),
                  icon: Icons.gavel_rounded,
                  color: Colors.orange.withValues(alpha: 0.1),
                  textColor: Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildModernInfoCard(
                  label: "Intérêts nets estimés",
                  value: currency.format(_netInterest),
                  icon: Icons.add_chart_rounded,
                  color: colorGreenFlash.withValues(alpha: 0.1),
                  textColor: isDark ? colorGreenFlash : colorGreenDark,
                ),
                const SizedBox(height: 12),
                _buildModernInfoCard(
                  label: "Valeur nette estimée",
                  value: currency.format(_totalNetValue),
                  icon: Icons.account_balance_wallet_rounded,
                  color: colorBlueMain.withValues(alpha: 0.1),
                  textColor: colorBlueMain,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernInfoCard({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
    Color? textColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            color ??
            (isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: textColor ?? (isDark ? Colors.white70 : Colors.black87),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: textColor ?? (isDark ? Colors.white : Colors.black),
              fontSize: 16,
              fontWeight: FontWeight.w900,
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
