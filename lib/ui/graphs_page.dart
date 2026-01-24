import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/graph_service.dart';
import 'login_page.dart';

class GraphsPage extends StatefulWidget {
  final String appName;
  final String appVersion;

  const GraphsPage({
    super.key,
    required this.appName,
    required this.appVersion,
  });

  @override
  State<GraphsPage> createState() => _GraphsPageState();
}

class _GraphsPageState extends State<GraphsPage> {
  final GraphService _graphService = GraphService();
  bool _isLoading = true;
  PatrimoineDistribution? _distribution;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final distribution = await _graphService.getPatrimoineDistribution();
      if (mounted) {
        setState(() {
          _distribution = distribution;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: Colors.purple,
            strokeWidth: 3,
          ),
        )
            : _distribution == null || _distribution!.total == 0
            ? _buildEmptyState()
            : _buildContent(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pie_chart_outline_rounded,
              size: 64,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune donnée disponible',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des comptes pour voir la répartition',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final distribution = _distribution!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Répartition',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),
          _buildCompactPieChart(),
          const SizedBox(height: 24),
          _buildCategoryCards(),
        ],
      ),
    );
  }

  Widget _buildCompactPieChart() {
    final distribution = _distribution!;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  _touchedIndex = -1;
                  return;
                }
                _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          sectionsSpace: 3,
          centerSpaceRadius: 50,
          sections: _buildPieSections(),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final distribution = _distribution!;
    final sections = <PieChartSectionData>[];
    int index = 0;

    void addSection(double value, Color color, String label, IconData icon) {
      if (value > 0) {
        final isTouched = index == _touchedIndex;
        final percent = (value / distribution.total) * 100;

        sections.add(
          PieChartSectionData(
            color: color,
            value: value,
            title: '${percent.toStringAsFixed(1)}%',
            radius: isTouched ? 95 : 85,
            titleStyle: TextStyle(
              fontSize: isTouched ? 15 : 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        );
        index++;
      }
    }

    addSection(distribution.liquidite, Colors.green.shade400, 'Liquidité', Icons.water_drop_rounded);
    addSection(distribution.epargne, Colors.blue.shade400, 'Épargne', Icons.savings_rounded);
    addSection(distribution.investissement, Colors.purple.shade400, 'Invest.', Icons.trending_up_rounded);
    addSection(distribution.avantages, Colors.orange.shade400, 'Avantages', Icons.card_giftcard_rounded);

    return sections;
  }

  Widget _buildCategoryCards() {
    final distribution = _distribution!;

    return Column(
      children: [
        if (distribution.liquidite > 0)
          _categoryCard(
            'Liquidités',
            distribution.liquidite,
            distribution.total,
            Colors.green.shade400,
            Icons.water_drop_rounded,
          ),
        if (distribution.epargne > 0)
          _categoryCard(
            'Épargne',
            distribution.epargne,
            distribution.total,
            Colors.blue.shade400,
            Icons.savings_rounded,
          ),
        if (distribution.investissement > 0)
          _categoryCard(
            'Investissements',
            distribution.investissement,
            distribution.total,
            Colors.purple.shade400,
            Icons.trending_up_rounded,
          ),
        if (distribution.avantages > 0)
          _categoryCard(
            'Avantages',
            distribution.avantages,
            distribution.total,
            Colors.orange.shade400,
            Icons.card_giftcard_rounded,
          ),
      ],
    );
  }

  Widget _categoryCard(String label, double value, double total, Color color, IconData icon) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final percent = (value / total) * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currencyFormat.format(value),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${percent.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}