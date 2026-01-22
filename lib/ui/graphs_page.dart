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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
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
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : _distribution == null || _distribution!.total == 0
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade300),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des comptes pour voir la répartition',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
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
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade900.withOpacity(0.25), Colors.purple.shade800.withOpacity(0.15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 60,
          sections: [
            if (distribution.liquidite > 0)
              _pieSection(distribution.liquidite, distribution.total, Colors.green, 'Liquidité'),
            if (distribution.epargne > 0)
              _pieSection(distribution.epargne, distribution.total, Colors.blue, 'Épargne'),
            if (distribution.investissement > 0)
              _pieSection(distribution.investissement, distribution.total, Colors.purple, 'Investissement'),
            if (distribution.avantages > 0)
              _pieSection(distribution.avantages, distribution.total, Colors.orange, 'Avantages'),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _pieSection(double value, double total, Color color, String label) {
    final percent = (value / total) * 100;
    return PieChartSectionData(
      color: color,
      value: value,
      title: '${percent.toStringAsFixed(1)}%',
      radius: 100,
      titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _buildLegend() {
    final distribution = _distribution!;
    return Column(
      children: [
        if (distribution.liquidite > 0) _legendItem(distribution.liquidite, distribution.total, Colors.green, 'Liquidité'),
        if (distribution.epargne > 0) _legendItem(distribution.epargne, distribution.total, Colors.blue, 'Épargne'),
        if (distribution.investissement > 0) _legendItem(distribution.investissement, distribution.total, Colors.purple, 'Investissement'),
        if (distribution.avantages > 0) _legendItem(distribution.avantages, distribution.total, Colors.orange, 'Avantages'),
        const Divider(height: 32, color: Colors.white24),
        _legendItem(distribution.total, distribution.total, Colors.grey, 'Total', isBold: true),
      ],
    );
  }

  Widget _legendItem(double value, double total, Color color, String label, {bool isBold = false}) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final percent = (value / total) * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(width: 20, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(currencyFormat.format(value), style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: Colors.white)),
              Text('${percent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 14, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}
