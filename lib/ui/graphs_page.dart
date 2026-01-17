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
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.appName),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.appVersion,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _distribution == null || _distribution!.total == 0
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des comptes pour voir la répartition',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition du patrimoine',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildPieChart(),
            const SizedBox(height: 32),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final distribution = _distribution!;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 60,
          sections: [
            if (distribution.liquidite > 0)
              PieChartSectionData(
                color: Colors.green,
                value: distribution.liquidite,
                title: '${((distribution.liquidite / distribution.total) * 100).toStringAsFixed(1)}%',
                radius: 100,
                titleStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            if (distribution.epargne > 0)
              PieChartSectionData(
                color: Colors.blue,
                value: distribution.epargne,
                title: '${((distribution.epargne / distribution.total) * 100).toStringAsFixed(1)}%',
                radius: 100,
                titleStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            if (distribution.investissement > 0)
              PieChartSectionData(
                color: Colors.purple,
                value: distribution.investissement,
                title: '${((distribution.investissement / distribution.total) * 100).toStringAsFixed(1)}%',
                radius: 100,
                titleStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            if (distribution.avantages > 0)
              PieChartSectionData(
                color: Colors.orange,
                value: distribution.avantages,
                title: '${((distribution.avantages / distribution.total) * 100).toStringAsFixed(1)}%',
                radius: 100,
                titleStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final distribution = _distribution!;

    return Column(
      children: [
        if (distribution.liquidite > 0)
          _buildLegendItem(
            color: Colors.green,
            label: 'Liquidité',
            value: distribution.liquidite,
            percentage: (distribution.liquidite / distribution.total) * 100,
          ),
        if (distribution.epargne > 0)
          _buildLegendItem(
            color: Colors.blue,
            label: 'Épargne',
            value: distribution.epargne,
            percentage: (distribution.epargne / distribution.total) * 100,
          ),
        if (distribution.investissement > 0)
          _buildLegendItem(
            color: Colors.purple,
            label: 'Investissement',
            value: distribution.investissement,
            percentage: (distribution.investissement / distribution.total) * 100,
          ),
        if (distribution.avantages > 0)
          _buildLegendItem(
            color: Colors.orange,
            label: 'Avantages',
            value: distribution.avantages,
            percentage: (distribution.avantages / distribution.total) * 100,
          ),
        const Divider(height: 32),
        _buildLegendItem(
          color: Colors.grey,
          label: 'Total',
          value: distribution.total,
          percentage: 100,
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required double value,
    required double percentage,
    bool isBold = false,
  }) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(value),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}