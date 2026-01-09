import 'package:flutter/material.dart';
import '../models/investment_position.dart';
import '../repositories/local_database_repository.dart';
import '../services/investment_service.dart';
import '../widgets/investment_summary_header.dart';
import '../widgets/investment_position_list.dart';
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

      if (!mounted) return;

      setState(() {
        positions = fetchedPositions;
        accountView = account;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  // ✅ Méthode pour ouvrir le dialog d'ajout
  void _openAddPositionDialog() {
    showDialog(
      context: context,
      builder: (context) => AddPositionDialog(
        onAdd: (ticker, name, quantity, pru) async {
          try {
            await investmentService.addPosition(
              userInvestmentAccountId: widget.userInvestmentAccountId,
              ticker: ticker,
              name: name,
              quantity: quantity,
              averagePurchasePrice: pru,
            );

            // Recharger les positions
            await _loadPositionsAndAccount();

            if (!mounted) return;

            // Capturer le ScaffoldMessengerState après l'await
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(
              SnackBar(
                content: Text('Position $ticker ajoutée avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            if (!mounted) return;

            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(
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
          onPressed: () {
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
              onValueUpdated: (newCash, newDeposits) async {
                try {
                  final hasChanged = await investmentService.updateInvestmentAccount(
                    userInvestmentAccountId: widget.userInvestmentAccountId,
                    cashBalance: newCash,
                    cumulativeDeposits: newDeposits,
                  );

                  await _loadPositionsAndAccount();

                  if (!mounted) return;

                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        hasChanged ? 'Compte mis à jour' : 'Aucun changement détecté',
                      ),
                      backgroundColor: hasChanged ? Colors.green : Colors.blue,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
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
              investmentService: investmentService,
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
