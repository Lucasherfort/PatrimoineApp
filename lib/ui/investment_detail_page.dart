// lib/pages/investment_detail_page.dart
import 'package:flutter/material.dart';
import '../models/investment_position.dart';
import '../models/investments/UserInvestmentAccountView.dart';
import '../services/investment_service.dart';
import '../widgets/Investment/investment_position_list.dart';
import '../widgets/Investment/investment_summary_header.dart';
import '../widgets/add_position_dialog.dart';

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
  final InvestmentService _investmentService = InvestmentService();

  List<InvestmentPosition> positions = [];
  UserInvestmentAccountView? accountView;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPositionsAndAccount();
  }

  Future<void> _loadPositionsAndAccount() async {
    setState(() => isLoading = true);

    try {
      // Charger les positions
      final fetchedPositions = await _investmentService.getInvestmentPositions(widget.userInvestmentAccountId);

      // Charger les informations du compte
      final accounts = await _investmentService.getInvestmentAccountsForUserWithPrices();
      final account = accounts.firstWhere(
            (acc) => acc.id == widget.userInvestmentAccountId,
        orElse: () => UserInvestmentAccountView(
          id: widget.userInvestmentAccountId,
          sourceName: widget.accountName,
          bankName: widget.bankName,
          totalContribution: 0,
          cashBalance: 0,
          amount: 0,
        ),
      );

      if (!mounted) return;

      setState(() {
        positions = fetchedPositions;
        accountView = account;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur _loadPositionsAndAccount: $e');
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openAddPositionDialog() {
    showDialog(
      context: context,
      builder: (context) => AddPositionDialog(
        onAdd: (ticker, name, quantity, pru) async {
          try {
            await _investmentService.addPosition(
              userInvestmentAccountId: widget.userInvestmentAccountId,
              ticker: ticker,
              name: name,
              quantity: quantity,
              averagePurchasePrice: pru,
            );

            // Recharger les positions
            await _loadPositionsAndAccount();

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Position $ticker ajoutée avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.accountName, style: const TextStyle(fontSize: 18)),
            Text(
              widget.bankName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
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
              onValueUpdated: (newCash, newDeposits) async {
                try {
                  final hasChanged = await _investmentService.updateInvestmentAccount(
                    userInvestmentAccountId: widget.userInvestmentAccountId,
                    cashBalance: newCash,
                    cumulativeDeposits: newDeposits,
                  );

                  await _loadPositionsAndAccount();

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        hasChanged
                            ? 'Compte mis à jour'
                            : 'Aucun changement détecté',
                      ),
                      backgroundColor: hasChanged
                          ? Colors.green
                          : Colors.blue,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          Expanded(
            child: InvestmentPositionList(
              positions: positions,
              isLoading: false,
              investmentService: _investmentService,
              onPositionUpdated: _loadPositionsAndAccount,
            ),
          ),
        ],
      ),
      floatingActionButton: isLoading
          ? null
          : FloatingActionButton.extended(
        onPressed: _openAddPositionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        tooltip: 'Ajouter une position',
      ),
    );
  }
}