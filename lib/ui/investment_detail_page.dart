import 'package:flutter/material.dart';
import '../models/investment_position.dart';
import '../services/investment_service.dart';
import '../repositories/local_database_repository.dart';

class InvestmentDetailPage extends StatefulWidget {
  final int userInvestmentAccountId;
  final String accountName;
  final String bankName;

  const InvestmentDetailPage({
    super.key,
    required this.userInvestmentAccountId,
    required this.accountName,
    required this.bankName,
  });

  @override
  State<InvestmentDetailPage> createState() => _InvestmentDetailPageState();
}

class _InvestmentDetailPageState extends State<InvestmentDetailPage> {
  List<InvestmentPosition> positions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPositions();
  }

  Future<void> _loadPositions() async {
    try {
      final repo = LocalDatabaseRepository();
      final db = await repo.load();
      final service = InvestmentService(db);

      final data = service.getPositionsForAccount(widget.userInvestmentAccountId);

      setState(() {
        positions = data;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement positions: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.accountName, style: const TextStyle(fontSize: 18)),
            Text(
              widget.bankName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : positions.isEmpty
          ? const Center(child: Text('Aucune position dans ce compte'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: positions.length,
        itemBuilder: (context, index) {
          final position = positions[index];
          return _buildPositionCard(position);
        },
      ),
    );
  }

  Widget _buildPositionCard(InvestmentPosition position) {
    final hasPrice = position.currentPrice != null;
    final isPositive = position.latentGain >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec ticker et nom
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    position.ticker,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    position.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              position.type,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const Divider(height: 24),

            // Quantité et PRU
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Quantité",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${position.quantity}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "PRU",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${position.averagePurchasePrice.toStringAsFixed(2)} €",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Prix actuel et valeur totale
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Prix actuel",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasPrice
                          ? "${position.currentPrice!.toStringAsFixed(2)} €"
                          : "N/A",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: hasPrice ? Colors.blue.shade700 : Colors.grey,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Valeur totale",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${position.totalValue.toStringAsFixed(2)} €",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Plus-value et performance
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPositive
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Plus-value latente",
                        style: TextStyle(
                          fontSize: 12,
                          color: isPositive
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${isPositive ? '+' : ''}${position.latentGain.toStringAsFixed(2)} €",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Performance",
                        style: TextStyle(
                          fontSize: 12,
                          color: isPositive
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${isPositive ? '+' : ''}${position.performance.toStringAsFixed(2)}%",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}