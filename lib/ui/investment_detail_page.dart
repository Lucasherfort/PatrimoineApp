import 'package:flutter/material.dart';
import '../models/investment_position.dart';
import '../services/investment_service.dart';
import '../repositories/local_database_repository.dart';
import '../widgets/investment_position_list.dart';

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

      // Utilise la méthode avec Google Sheets
      final data = await service.getPositionsWithPrices(widget.userInvestmentAccountId);

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
        actions: [
          if (!isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  isLoading = true;
                });
                _loadPositions();
              },
              tooltip: 'Actualiser les cours',
            ),
        ],
      ),
      body: InvestmentPositionList(
        positions: positions,
        isLoading: isLoading,
      ),
    );
  }
}