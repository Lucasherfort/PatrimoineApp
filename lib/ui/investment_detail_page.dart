import 'package:flutter/material.dart';
import '../models/investment_position.dart';
import '../models/investments/user_investment_account_view.dart';
import '../models/position.dart';
import '../services/investment_service.dart';
import '../services/position_service.dart';
import '../widgets/Investment/investment_position_list.dart';
import '../widgets/Investment/investment_summary_header.dart';
import '../widgets/position/add_position_dialog.dart';

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
  final PositionService _positionService = PositionService();

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
      final fetchedPositions =
      await _investmentService.getInvestmentPositions(
        widget.userInvestmentAccountId,
      );

      final accounts =
      await _investmentService.getInvestmentAccountsForUserWithPrices();

      final account = accounts.firstWhere(
            (acc) => acc.id == widget.userInvestmentAccountId,
        orElse: () => UserInvestmentAccountView(
          id: widget.userInvestmentAccountId,
          sourceName: widget.accountName,
          bankName: widget.bankName,
          totalContribution: 0,
          cashBalance: 0,
          amount: 0,
          logoUrl: '',
        ),
      );

      if (!mounted) return;

      setState(() {
        positions = fetchedPositions;
        accountView = account;
        isLoading = false;
      });

      if (account.totalContribution == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Attention : les dépôts cumulés de ce compte sont à 0.',
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _openAddPositionDialog() {
    showDialog(
      context: context,
      builder: (context) => AddPositionDialog(
        onAdd: (Position position, double quantity, double pru) async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);

          try {
            await _positionService.addPosition(
              userInvestmentAccountId: widget.userInvestmentAccountId,
              positionId: position.id,
              quantity: quantity,
              averagePurchasePrice: pru,
            );

            await _loadPositionsAndAccount();

            if (!mounted) return;

            scaffoldMessenger.showSnackBar(
              SnackBar(
                content:
                Text('Position ${position.ticker} ajoutée avec succès'),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          } catch (e) {
            if (!mounted) return;

            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Erreur : $e'),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.accountName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              widget.bankName,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          if (!isLoading)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
                onPressed: _loadPositionsAndAccount,
                tooltip: 'Actualiser les cours',
              ),
            ),
          if (!isLoading)
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade600,
                    Colors.purple.shade800,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.purple.shade800.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: _openAddPositionDialog,
                tooltip: 'Ajouter une position',
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E293B),
              Color(0xFF0F172A),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          )
              : Column(
            children: [
              if (accountView != null)
                InvestmentSummaryHeader(
                  account: accountView!,
                  positions: positions,
                  onValueUpdated:
                      (newCash, newDeposits) async {
                    final scaffoldMessenger =
                    ScaffoldMessenger.of(context);

                    try {
                      final hasChanged =
                      await _investmentService
                          .updateInvestmentAccount(
                        userInvestmentAccountId:
                        widget.userInvestmentAccountId,
                        cashBalance: newCash,
                        cumulativeDeposits: newDeposits,
                      );

                      await _loadPositionsAndAccount();

                      if (!mounted) return;

                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            hasChanged
                                ? 'Compte mis à jour'
                                : 'Aucun changement détecté',
                          ),
                          backgroundColor: hasChanged
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                          duration:
                          const Duration(seconds: 2),
                          behavior:
                          SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(8),
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Erreur: $e'),
                          backgroundColor:
                          Colors.red.shade700,
                          duration:
                          const Duration(seconds: 3),
                          behavior:
                          SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                  },
                ),
              Expanded(
                child: InvestmentPositionList(
                  positions: positions,
                  isLoading: false,
                  positionService: _positionService,
                  onPositionUpdated:
                  _loadPositionsAndAccount,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
