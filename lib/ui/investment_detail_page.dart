import 'package:flutter/material.dart';
import '../models/investment_position.dart';
import '../repositories/local_database_repository.dart';
import '../services/investment_service.dart';
import '../widgets/InvestmentSummaryHeader.dart';
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
  UserInvestmentAccountView? accountView;
  bool isLoading = true;

  late InvestmentService investmentService;

  @override
  void initState() {
    super.initState();
    _initServiceAndLoad();
  }

  Future<void> _initServiceAndLoad() async {
    try {
      final repo = LocalDatabaseRepository();
      final db = await repo.load();
      investmentService = InvestmentService(db);

      await _loadPositionsAndAccount();
    } catch (e) {
      print('Erreur initialisation: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadPositionsAndAccount() async {
    setState(() => isLoading = true);

    try {
      final fetchedPositions = await investmentService.getInvestmentPositions(
        widget.userInvestmentAccountId,
      );

      final accounts = await investmentService.getInvestmentAccountsForUserWithPrices(1);
      final account = accounts.firstWhere(
            (acc) => acc.id == widget.userInvestmentAccountId,
      );

      setState(() {
        positions = fetchedPositions;
        accountView = account;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement positions: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // ✅ Retourne true pour indiquer qu'il faut recharger
            Navigator.pop(context, true);
          },
        ),
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
              onPressed: _loadPositionsAndAccount,
              tooltip: 'Actualiser les cours',
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (accountView != null)
            InvestmentSummaryHeader(
              account: accountView!,
              positions: positions,
            ),
          Expanded(
            child: InvestmentPositionList(
              positions: positions,
              isLoading: false,
            ),
          ),
        ],
      ),
    );
  }
}