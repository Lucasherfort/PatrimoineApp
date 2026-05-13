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

  // --- Palette de couleurs cohérente ---
  static const Color colorDarkBg = Color(0xFF060B26);
  static const Color colorBlueMain = Color(0xFF0D71EE);

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
      final fetchedPositions = await _investmentService.getInvestmentPositions(
        widget.userInvestmentAccountId,
      );
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
          logoUrl: '',
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  void _openAddPositionDialog() {
    showDialog(
      context: context,
      builder: (context) => AddPositionDialog(
        existingPositions: positions,
        onAdd: (Position position, double quantity, double pru) async {
          try {
            await _positionService.addPosition(
              userInvestmentAccountId: widget.userInvestmentAccountId,
              positionId: position.id,
              quantity: quantity,
              averagePurchasePrice: pru,
            );
            await _loadPositionsAndAccount();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorDarkBg, // Fond ultra sombre
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // --- EFFET DE FOND (Halos lumineux) ---
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorBlueMain.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple.withValues(alpha: 0.08), // Un rappel de la couleur investissement
              ),
            ),
          ),

          // --- CONTENU ---
          SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Column(
              children: [
                if (accountView != null)
                  InvestmentSummaryHeader(
                    account: accountView!,
                    positions: positions,
                    onValueUpdated: _handleValueUpdated,
                  ),
                Expanded(
                  child: InvestmentPositionList(
                    positions: positions,
                    isLoading: false,
                    positionService: _positionService,
                    onPositionUpdated: _loadPositionsAndAccount,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context, true),
      ),
      centerTitle: true,
      title: Column(
        children: [
          Text(
            widget.accountName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            widget.bankName,
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.white),
          onPressed: _openAddPositionDialog,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _handleValueUpdated(double newCash, double newDeposits) async {
    try {
      await _investmentService.updateInvestmentAccount(
        userInvestmentAccountId: widget.userInvestmentAccountId,
        cashBalance: newCash,
        cumulativeDeposits: newDeposits,
      );
      await _loadPositionsAndAccount();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }
}