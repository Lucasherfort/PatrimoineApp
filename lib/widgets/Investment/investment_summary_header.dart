import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/investment_position.dart';
import '../../models/investments/user_investment_account_view.dart';

class InvestmentSummaryHeader extends StatelessWidget {
  final UserInvestmentAccountView account;
  final List<InvestmentPosition> positions;
  final void Function(double newCashBalance, double newCumulativeDeposits)? onValueUpdated;

  const InvestmentSummaryHeader({
    super.key,
    required this.account,
    required this.positions,
    this.onValueUpdated,
  });

  // --- Palette ---
  static const Color colorGreenFlash = Color(0xFF65E046);
  static const Color colorOrangeLogo = Color(0xFFD98006);
  static const Color colorBlueMain = Color(0xFF0D71EE);

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: 2);
    return formatter.format(amount).trim();
  }

  bool get isAssuranceVie => account.isAssuranceVie;
  double get positionsValue => positions.fold(0.0, (sum, pos) => sum + pos.totalValue);
  double get totalValue => isAssuranceVie ? positionsValue : account.cashBalance + positionsValue;
  double get totalProfitLoss => totalValue - account.totalContribution;
  double get performancePercentage {
    if (account.totalContribution <= 0) return 0.0;
    return ((totalValue - account.totalContribution) / account.totalContribution) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final isProfit = totalProfitLoss >= 0;
    final statusColor = isProfit ? colorGreenFlash : colorOrangeLogo;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          // Titre discret
          Text(
            "VALEUR TOTALE ESTIMÉE",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),

          // Montant Principal
          Text(
            "${_formatAmount(totalValue)} €",
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 12),

          // Badge de Performance
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(isProfit ? Icons.trending_up : Icons.trending_down,
                        color: statusColor, size: 16),
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
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_outlined, color: Colors.white54, size: 16),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Métriques secondaires en ligne épurée
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!isAssuranceVie) ...[
                  _buildMetricItem("ESPÈCES", "${_formatAmount(account.cashBalance)} €"),
                  VerticalDivider(color: Colors.white.withValues(alpha: 0.1), indent: 8, endIndent: 8),
                ],
                _buildMetricItem("VERSEMENTS", "${_formatAmount(account.totalContribution)} €"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // --- MODAL DE MODIFICATION (VERSION DARK PREMIUM) ---
  void _openEditPanel(BuildContext context) {
    final cashController = TextEditingController(text: account.cashBalance.toStringAsFixed(2).replaceAll('.', ','));
    final depositsController = TextEditingController(text: account.totalContribution.toStringAsFixed(2).replaceAll('.', ','));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A), // Dark Navy
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text("Ajuster le compte", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            if (!isAssuranceVie)
              _buildModernField(cashController, "Espèces disponibles", Icons.account_balance_wallet_outlined),
            const SizedBox(height: 16),
            _buildModernField(depositsController, "Total des versements", Icons.savings_outlined),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorBlueMain,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  final cash = double.tryParse(cashController.text.replaceAll(',', '.'));
                  final deposits = double.tryParse(depositsController.text.replaceAll(',', '.'));
                  if (deposits != null && onValueUpdated != null) {
                    onValueUpdated!(isAssuranceVie ? 0.0 : (cash ?? 0.0), deposits);
                  }
                  Navigator.pop(context);
                },
                child: const Text("SAUVEGARDER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: colorBlueMain),
        suffixText: "€",
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}