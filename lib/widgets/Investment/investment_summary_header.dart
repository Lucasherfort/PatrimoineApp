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

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(amount).trim();
  }

  bool get isAssuranceVie => account.isAssuranceVie;

  double get positionsValue {
    return positions.fold(0.0, (sum, position) => sum + position.totalValue);
  }

  double get totalValue => isAssuranceVie
      ? positionsValue
      : account.cashBalance + positionsValue;

  double get totalProfitLoss {
    return totalValue - account.totalContribution;
  }

  double get performancePercentage {
    if (account.totalContribution <= 0) return 0.0;
    return ((totalValue - account.totalContribution) / account.totalContribution) * 100;
  }

  void _openEditPanel(BuildContext context) {
    final cashController = TextEditingController(
      text: account.cashBalance.toStringAsFixed(2).replaceAll('.', ','),
    );
    final depositsController = TextEditingController(
      text: account.totalContribution.toStringAsFixed(2).replaceAll('.', ','),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Modifier ${account.sourceName}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              if (!isAssuranceVie) ...[
                TextField(
                  controller: cashController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Espèces disponibles",
                    suffixText: "€",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_wallet),
                    helperText: "Montant en espèces sur le compte",
                  ),
                ),
                const SizedBox(height: 12),
              ],

              TextField(
                controller: depositsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Versements cumulés",
                  suffixText: "€",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.savings),
                  helperText: "Total des versements effectués",
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final cashText = cashController.text.replaceAll(',', '.');
                    final depositsText = depositsController.text.replaceAll(',', '.');

                    final cash = isAssuranceVie
                        ? 0.0
                        : double.tryParse(cashText);
                    final deposits = double.tryParse(depositsText);

                    if ((isAssuranceVie || cash != null) &&
                        deposits != null &&
                        onValueUpdated != null) {

                      final newCash = isAssuranceVie ? 0.0 : cash!;
                      final newDeposits = deposits;

                      final cashChanged = !isAssuranceVie &&
                          newCash.toStringAsFixed(2) != account.cashBalance.toStringAsFixed(2);

                      final depositsChanged =
                          newDeposits.toStringAsFixed(2) !=
                              account.totalContribution.toStringAsFixed(2);

                      if (cashChanged || depositsChanged) {
                        onValueUpdated!(newCash, newDeposits);
                      }
                    }

                    Navigator.pop(context);
                  },
                  child: const Text("Valider"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isProfit = totalProfitLoss >= 0;

    return InkWell(
      onTap: () => _openEditPanel(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E293B), // slate-800
              Color(0xFF334155), // slate-700
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // Ligne principale : Valeur totale + Performance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Valeur totale
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Valeur totale",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${_formatAmount(totalValue)} €",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  // Performance mise en évidence
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Pourcentage de gain en grand
                      Text(
                        "${isProfit ? '+' : ''}${performancePercentage.toStringAsFixed(2)}%",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: isProfit
                              ? Colors.green.shade400
                              : Colors.red.shade400,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Montant du gain avec icône
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isProfit
                                ? Colors.green.shade300
                                : Colors.red.shade300,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${isProfit ? '+' : ''}${_formatAmount(totalProfitLoss)} €",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isProfit
                                  ? Colors.green.shade300
                                  : Colors.red.shade300,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Ligne inférieure : Métriques compactes
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isAssuranceVie
                    ? _buildAssuranceVieMetrics()
                    : _buildPEAMetrics(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Métriques PEA compactes
  Widget _buildPEAMetrics() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildCompactMetric(
          icon: Icons.account_balance_wallet,
          label: "Espèces",
          value: "${_formatAmount(account.cashBalance)} €",
        ),
        Container(
          width: 1,
          height: 32,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        _buildCompactMetric(
          icon: Icons.savings,
          label: "Versements",
          value: "${_formatAmount(account.totalContribution)} €",
        ),
      ],
    );
  }

  // Métriques Assurance Vie compactes
  Widget _buildAssuranceVieMetrics() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCompactMetric(
          icon: Icons.savings,
          label: "Versements cumulés",
          value: "${_formatAmount(account.totalContribution)} €",
        ),
      ],
    );
  }

  Widget _buildCompactMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.75),
          size: 16,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}