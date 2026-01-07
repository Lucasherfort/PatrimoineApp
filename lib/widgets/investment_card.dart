import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../ui/investment_detail_page.dart';

class InvestmentCard extends StatelessWidget {
  final int userInvestmentAccountId;
  final String name;
  final String type;
  final String bankName;
  final double totalValue;
  final double performance;
  final VoidCallback? onTap;

  const InvestmentCard({
    super.key,
    required this.userInvestmentAccountId,
    required this.name,
    required this.type,
    required this.bankName,
    required this.totalValue,
    required this.performance,
    this.onTap,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(amount).trim();
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = performance >= 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final shouldReload = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvestmentDetailPage(
                userInvestmentAccountId: userInvestmentAccountId,
                accountName: name,
                bankName: bankName,
              ),
            ),
          );

          if (shouldReload == true && onTap != null) {
            onTap!();
          }
        },
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: Colors.purple.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        bankName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${_formatAmount(totalValue)} €",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      "${isPositive ? '+' : ''}${performance.toStringAsFixed(2)}%",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}