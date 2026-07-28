import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/investment_position.dart';
import '../../models/investments/user_investment_account_view.dart';
import '../../services/investment_service.dart';

class InvestmentSummaryHeader extends StatefulWidget {
  final UserInvestmentAccountView account;
  final List<InvestmentPosition> positions;
  final void Function(
    double newCashBalance,
    double newCumulativeDeposits,
    DateTime? newOpenedAt,
  )?
  onValueUpdated;

  const InvestmentSummaryHeader({
    super.key,
    required this.account,
    required this.positions,
    this.onValueUpdated,
  });

  @override
  State<InvestmentSummaryHeader> createState() =>
      _InvestmentSummaryHeaderState();
}

class _InvestmentSummaryHeaderState extends State<InvestmentSummaryHeader> {
  bool _isVisible = true;

  // --- Palette ---
  static const Color colorGreenFlash = Color(0xFF65E046);
  static const Color colorGreenDark = Color(0xFF15803D);
  static const Color colorOrangeLogo = Color(0xFFD98006);
  static const Color colorOrangeDark = Color(0xFFC2410C);
  static const Color colorBlueMain = Color(0xFF0D71EE);

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(amount).trim();
  }

  bool get isAssuranceVie => widget.account.isAssuranceVie;
  double get positionsValue =>
      widget.positions.fold(0.0, (sum, pos) => sum + pos.totalValue);
  double get totalValue => isAssuranceVie
      ? positionsValue
      : widget.account.cashBalance + positionsValue;

  double get totalProfitLoss => totalValue - widget.account.totalContribution;
  double get performancePercentage {
    if (widget.account.totalContribution <= 0) return 0.0;
    return ((totalValue - widget.account.totalContribution) /
            widget.account.totalContribution) *
        100;
  }

  String _getAccountAge() {
    if (widget.account.openedAt == null) return "Inconnue";
    final diff = DateTime.now().difference(widget.account.openedAt!);
    final years = (diff.inDays / 365.25).floor();
    final months = ((diff.inDays % 365.25) / 30.44).floor();

    if (years > 0) {
      return "$years an${years > 1 ? 's' : ''} et $months mois";
    }
    return "$months mois";
  }

  void _showDetailsPanel(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textStyle = theme.textTheme;

    final service = InvestmentService();
    // On calcule la valeur nette explicitement pour le panneau
    final netEstimatedValue = service.calculateNetValueNet(
      widget.account.copyWith(amount: totalValue),
    );

    final netGain = netEstimatedValue - widget.account.totalContribution;
    final taxRate = service.getCurrentTaxRate(widget.account);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
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
                // Barre de drag
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Text(
                  "DÉTAILS FISCAUX",
                  style: textStyle.labelSmall?.copyWith(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 24),

                _buildModernInfoCard(
                  context,
                  label: "Ancienneté du compte",
                  value: _getAccountAge(),
                  icon: Icons.history_rounded,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.grey.shade100,
                ),
                const SizedBox(height: 12),

                _buildModernInfoCard(
                  context,
                  label: "Fiscalité appliquée",
                  value: "${(taxRate * 100).toStringAsFixed(1)} %",
                  icon: Icons.receipt_long_rounded,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.grey.shade100,
                ),
                const SizedBox(height: 32),

                Text(
                  "Estimation nette",
                  style: textStyle.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                _buildModernInfoCard(
                  context,
                  label: "Plus-value nette estimée",
                  value: _isVisible
                      ? "${netGain >= 0 ? '+' : ''}${_formatAmount(netGain)} €"
                      : "•••• €",
                  icon: Icons.trending_up_rounded,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.grey.shade100,
                ),
                const SizedBox(height: 12),

                _buildModernInfoCard(
                  context,
                  label: "Valeur nette estimée",
                  value: _isVisible
                      ? "${_formatAmount(netEstimatedValue)} €"
                      : "•••• €",
                  icon: Icons.verified_user_rounded,
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

  Widget _buildModernInfoCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    Color? textColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProfit = totalProfitLoss >= 0;
    final statusColor = isProfit
        ? (isDark ? colorGreenFlash : colorGreenDark)
        : (isDark ? colorOrangeLogo : colorOrangeDark);
    final mainTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final service = InvestmentService();
    final double taxRate = service.getCurrentTaxRate(widget.account);
    final bool isAdvantageAcquired = service.isTaxAdvantageAcquired(
      widget.account,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          // Titre discret
          Text(
            "VALEUR TOTALE ESTIMÉE",
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.black45,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),

          // Montant Principal (Cliquable)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Placeholder invisible pour garder le centrage
              const Opacity(
                opacity: 0,
                child: IconButton(
                  onPressed: null,
                  icon: Icon(Icons.visibility_outlined, size: 22),
                ),
              ),

              Expanded(
                child: GestureDetector(
                  onTap: () => _showDetailsPanel(context),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _isVisible
                            ? "${_formatAmount(totalValue)} €"
                            : "•••••••• €",
                        key: ValueKey(_isVisible),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: mainTextColor,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bouton visibilité
              IconButton(
                onPressed: () {
                  setState(() {
                    _isVisible = !_isVisible;
                  });
                },
                icon: Icon(
                  _isVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: isDark ? Colors.white70 : Colors.black45,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Badge de Performance
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isProfit ? Icons.trending_up : Icons.trending_down,
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isVisible
                          ? "${isProfit ? '+' : ''}${_formatAmount(totalProfitLoss)} € (${performancePercentage.toStringAsFixed(2)}%)"
                          : "•••• €",
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Petit bouton edit style "Glass"
              GestureDetector(
                onTap: () => _openEditPanel(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: isDark ? Colors.white54 : Colors.black38,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Métriques secondaires
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                if (!isAssuranceVie)
                  Expanded(
                    child: _buildMetricItem(
                      context,
                      "ESPÈCES",
                      _isVisible
                          ? "${_formatAmount(widget.account.cashBalance)} €"
                          : "•••• €",
                    ),
                  ),
                Expanded(
                  child: _buildMetricItem(
                    context,
                    "VERSEMENTS",
                    _isVisible
                        ? "${_formatAmount(widget.account.totalContribution)} €"
                        : "•••• €",
                  ),
                ),
                if (widget.account.openedAt != null)
                  Expanded(
                    child: _buildMetricItem(
                      context,
                      "FISCALITÉ",
                      "${(taxRate * 100).toStringAsFixed(1)}%",
                      subtitle: isAdvantageAcquired
                          ? "AVANTAGE ACQUIS"
                          : "PLEIN TAUX",
                      statusColor: isAdvantageAcquired
                          ? (isDark ? colorGreenFlash : colorGreenDark)
                          : Colors.orange,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context,
    String label,
    String value, {
    String? subtitle,
    Color? statusColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.black38,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              style: TextStyle(
                color:
                    statusColor ??
                    (isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black26),
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }

  // --- MODAL DE MODIFICATION ---
  void _openEditPanel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final cashController = TextEditingController(
      text: widget.account.cashBalance.toStringAsFixed(2).replaceAll('.', ','),
    );
    final depositsController = TextEditingController(
      text: widget.account.totalContribution
          .toStringAsFixed(2)
          .replaceAll('.', ','),
    );

    DateTime? selectedDate = widget.account.openedAt;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Ajuster le compte",
                  style: TextStyle(
                    color: theme.textTheme.titleLarge?.color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 24),
                if (!isAssuranceVie)
                  _buildModernField(
                    context,
                    cashController,
                    "Espèces disponibles",
                    Icons.account_balance_wallet_outlined,
                  ),
                const SizedBox(height: 16),
                _buildModernField(
                  context,
                  depositsController,
                  "Total des versements",
                  Icons.savings_outlined,
                ),
                const SizedBox(height: 16),

                // Sélecteur de date d'ouverture
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      locale: const Locale('fr', 'FR'),
                      builder: (context, child) {
                        return Theme(
                          data: theme.copyWith(
                            colorScheme: theme.colorScheme.copyWith(
                              primary: colorBlueMain,
                              onPrimary: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: colorBlueMain,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Date d'ouverture",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black45,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                selectedDate != null
                                    ? DateFormat(
                                        'dd MMMM yyyy',
                                        'fr_FR',
                                      ).format(selectedDate!)
                                    : "Non renseignée",
                                style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selectedDate != null)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () =>
                                setModalState(() => selectedDate = null),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorBlueMain,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      final cash = double.tryParse(
                        cashController.text.replaceAll(',', '.'),
                      );
                      final deposits = double.tryParse(
                        depositsController.text.replaceAll(',', '.'),
                      );
                      if (deposits != null && widget.onValueUpdated != null) {
                        widget.onValueUpdated!(
                          isAssuranceVie ? 0.0 : (cash ?? 0.0),
                          deposits,
                          selectedDate,
                        );
                      }
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "SAUVEGARDER",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
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

  Widget _buildModernField(
    BuildContext context,
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontWeight: FontWeight.bold,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black45),
        prefixIcon: Icon(icon, color: colorBlueMain),
        suffixText: "€",
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
