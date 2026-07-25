import 'package:flutter/material.dart';
import '../models/investment_position.dart';
import '../models/investments/user_investment_account_view.dart';
import '../models/position.dart';
import '../services/investment_service.dart';
import '../services/position_service.dart';
import '../widgets/Investment/investment_position_list.dart';
import '../widgets/Investment/investment_summary_header.dart';
import '../widgets/Investment/investment_projection_tab.dart';
import '../widgets/position/add_position_dialog.dart';

class InvestmentDetailPage extends StatefulWidget {
  final int userInvestmentAccountId;
  final int investmentCategoryId; // 👈 Ajouté
  final String accountName;
  final String bankName;

  const InvestmentDetailPage({
    super.key,
    required this.userInvestmentAccountId,
    required this.investmentCategoryId, // 👈 Ajouté
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
  int _currentIndex = 0;

  bool get _isPEA => widget.accountName.toUpperCase().contains('PEA');

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
      final accounts = await _investmentService
          .getInvestmentAccountsForUserWithPrices();

      final account = accounts.firstWhere(
        (acc) => acc.id == widget.userInvestmentAccountId,
        orElse: () => UserInvestmentAccountView(
          id: widget.userInvestmentAccountId,
          investmentCategoryId: widget.investmentCategoryId,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  void _openAddPositionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
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

            if (!context.mounted) return;

            await _loadPositionsAndAccount();
          } catch (e) {
            if (!context.mounted) return;

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorDarkBg : const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
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
                color: colorBlueMain.withValues(alpha: isDark ? 0.15 : 0.08),
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
                color: Colors.purple.withValues(
                  alpha: isDark ? 0.08 : 0.05,
                ), // Un rappel de la couleur investissement
              ),
            ),
          ),

          // --- CONTENU ---
          SafeArea(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: isDark ? Colors.white : colorBlueMain,
                    ),
                  )
                : IndexedStack(
                    index: _currentIndex,
                    children: [
                      _buildAccountMainTab(),
                      _buildCompoundInterestTab(),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _isPEA ? _buildBottomNavBar(context) : null,
    );
  }

  Widget _buildAccountMainTab() {
    return Column(
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
    );
  }

  Widget _buildCompoundInterestTab() {
    if (accountView == null) return const SizedBox();

    final positionsValue = positions.fold(0.0, (sum, pos) => sum + pos.totalValue);
    final totalValueGross = accountView!.cashBalance + positionsValue;
    
    // On calcule le PnL brut pour le simulateur (plus simple à projeter)
    final pnl = totalValueGross - accountView!.totalContribution;

    return InvestmentProjectionTab(
      initialDeposits: accountView!.totalContribution,
      initialPnL: pnl,
      openedAt: accountView!.openedAt,
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: theme.cardColor,
        selectedItemColor: colorBlueMain,
        unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.business_center),
            label: 'Compte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_rounded),
            label: 'Projections',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : const Color(0xFF0F172A);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: color, size: 20),
        onPressed: () => Navigator.pop(context, true),
      ),
      centerTitle: true,
      title: Column(
        children: [
          Text(
            widget.accountName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            widget.bankName,
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.5)),
          ),
        ],
      ),
      actions: [
        if (_currentIndex == 0)
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: color),
            onPressed: _openAddPositionDialog,
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _handleValueUpdated(
    double newCash,
    double newDeposits,
    DateTime? newOpenedAt,
  ) async {
    try {
      await _investmentService.updateInvestmentAccount(
        userInvestmentAccountId: widget.userInvestmentAccountId,
        cashBalance: newCash,
        cumulativeDeposits: newDeposits,
        openedAt: newOpenedAt,
      );
      await _loadPositionsAndAccount();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }
}
