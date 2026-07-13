import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/investment_position.dart';
import '../../models/investments/user_investment_account_view.dart';
import '../../services/investment_service.dart';
import '../../services/theme_manager.dart';

class InvestmentSummaryHeader extends StatelessWidget {
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

  bool get isAssuranceVie => account.isAssuranceVie;
  double get positionsValue =>
      positions.fold(0.0, (sum, pos) => sum + pos.totalValue);
  double get totalValue =>
      isAssuranceVie ? positionsValue : account.cashBalance + positionsValue;

  double get displayedValue {
    final service = InvestmentService();
    // On met à jour l'objet pour le calcul sans modifier l'original par sécurité
    final tempView = UserInvestmentAccountView(
      id: account.id,
      investmentCategoryId: account.investmentCategoryId,
      sourceName: account.sourceName,
      bankName: account.bankName,
      logoUrl: account.logoUrl,
      totalContribution: account.totalContribution,
      cashBalance: account.cashBalance,
      amount: totalValue,
      openedAt: account.openedAt,
    );
    return service.calculateNetValue(tempView);
  }

  double get totalProfitLoss => displayedValue - account.totalContribution;
  double get performancePercentage {
    if (account.totalContribution <= 0) return 0.0;
    return ((displayedValue - account.totalContribution) /
            account.totalContribution) *
        100;
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
    final double taxRate = service.getCurrentTaxRate(account);
    final bool isAdvantageAcquired = service.isTaxAdvantageAcquired(account);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          // Titre discret
          Text(
            ThemeManager().displayNetWealth
                ? "VALEUR NETTE ESTIMÉE"
                : "VALEUR TOTALE ESTIMÉE",
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

          // Montant Principal
          Text(
            "${_formatAmount(displayedValue)} €",
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: mainTextColor,
              letterSpacing: -1.0,
            ),
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
                      "${isProfit ? '+' : ''}${_formatAmount(totalProfitLoss)} € (${performancePercentage.toStringAsFixed(2)}%)",
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
              // Petit bouton info/edit style "Glass"
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
                      "${_formatAmount(account.cashBalance)} €",
                    ),
                  ),
                Expanded(
                  child: _buildMetricItem(
                    context,
                    "VERSEMENTS",
                    "${_formatAmount(account.totalContribution)} €",
                  ),
                ),
                if (account.openedAt != null)
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
      text: account.cashBalance.toStringAsFixed(2).replaceAll('.', ','),
    );
    final depositsController = TextEditingController(
      text: account.totalContribution.toStringAsFixed(2).replaceAll('.', ','),
    );

    DateTime? selectedDate = account.openedAt;

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
                      if (deposits != null && onValueUpdated != null) {
                        onValueUpdated!(
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
