import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/investments/investment_projection_data.dart';
import '../../services/financial_profile_manager.dart';

class InvestmentProjectionTab extends StatefulWidget {
  final double initialDeposits;
  final double initialPnL;
  final DateTime? openedAt;

  const InvestmentProjectionTab({
    super.key,
    required this.initialDeposits,
    required this.initialPnL,
    this.openedAt,
  });

  @override
  State<InvestmentProjectionTab> createState() =>
      _InvestmentProjectionTabState();
}

class _InvestmentProjectionTabState extends State<InvestmentProjectionTab> {
  late double _pastDeposits;
  late double _pastPnL;
  late TextEditingController _depositsController;
  late TextEditingController _pnlController;
  late TextEditingController _dcaController;
  late TextEditingController _rateController;
  late TextEditingController _horizonController;

  double _monthlyContribution = 200.0;
  double _annualRate = 6.0;
  int _horizonYears = 10;

  final _formatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _pastDeposits = widget.initialDeposits;
    _pastPnL = widget.initialPnL;
    _depositsController = TextEditingController(
      text: _pastDeposits.toStringAsFixed(0),
    );
    _pnlController = TextEditingController(text: _pastPnL.toStringAsFixed(0));

    final profile = FinancialProfileManager();
    _monthlyContribution = profile.monthlyInvestment > 0
        ? profile.monthlyInvestment
        : 200.0;

    // Default horizon calculation
    if (widget.openedAt != null) {
      final ageInYears =
          DateTime.now().difference(widget.openedAt!).inDays / 365.25;
      _horizonYears = max(1, (8 - ageInYears).ceil());
      if (ageInYears >= 8) _horizonYears = 10;
    }

    _dcaController = TextEditingController(
      text: _monthlyContribution.toStringAsFixed(0),
    );
    _rateController = TextEditingController(
      text: _annualRate.toStringAsFixed(1),
    );
    _horizonController = TextEditingController(text: _horizonYears.toString());
  }

  @override
  void didUpdateWidget(covariant InvestmentProjectionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Smart Sync: Only update the PnL if it changed in the widget AND the user
    // hasn't manually modified it (or they matched the previous real value).
    if (widget.initialPnL != oldWidget.initialPnL) {
      if (_pastPnL == oldWidget.initialPnL) {
        setState(() {
          _pastPnL = widget.initialPnL;
          _pnlController.text = _pastPnL.toStringAsFixed(0);
        });
      }
    }
  }

  @override
  void dispose() {
    _depositsController.dispose();
    _pnlController.dispose();
    _dcaController.dispose();
    _rateController.dispose();
    _horizonController.dispose();
    super.dispose();
  }

  void _resetToReal() {
    setState(() {
      _pastDeposits = widget.initialDeposits;
      _pastPnL = widget.initialPnL;
      _depositsController.text = _pastDeposits.toStringAsFixed(0);
      _pnlController.text = _pastPnL.toStringAsFixed(0);

      final profile = FinancialProfileManager();
      _monthlyContribution = profile.monthlyInvestment > 0
          ? profile.monthlyInvestment
          : 200.0;
      _dcaController.text = _monthlyContribution.toStringAsFixed(0);

      _annualRate = 6.0;
      _rateController.text = _annualRate.toStringAsFixed(1);
    });
  }

  List<InvestmentProjectionPoint> _calculateProjections() {
    List<InvestmentProjectionPoint> points = [];
    double currentBalance = _pastDeposits + _pastPnL;
    double cumulativeDeposits = _pastDeposits;

    // Add point 0
    points.add(
      InvestmentProjectionPoint(
        year: 0,
        savingsEffort: _pastDeposits,
        totalInterests: _pastPnL,
        totalBalance: currentBalance,
      ),
    );

    final monthlyRate = (_annualRate / 100) / 12;
    const double peaLimit = 150000.0;

    for (int m = 1; m <= _horizonYears * 12; m++) {
      // Calculate remaining capacity before reaching the 150k€ limit
      final remainingCapacity = max(0.0, peaLimit - cumulativeDeposits);
      // Monthly contribution is capped by remaining capacity
      final actualContribution = min(_monthlyContribution, remainingCapacity);

      cumulativeDeposits += actualContribution;
      currentBalance =
          (currentBalance + actualContribution) * (1 + monthlyRate);

      if (m % 12 == 0) {
        final year = m ~/ 12;
        points.add(
          InvestmentProjectionPoint(
            year: year,
            savingsEffort: cumulativeDeposits,
            totalInterests: currentBalance - cumulativeDeposits,
            totalBalance: currentBalance,
          ),
        );
      }
    }
    return points;
  }

  int? _findLimitReachedYear(List<InvestmentProjectionPoint> projections) {
    const double peaLimit = 150000.0;
    // If already above limit at start
    if (_pastDeposits >= peaLimit) return 0;

    for (var point in projections) {
      if (point.savingsEffort >= peaLimit) return point.year;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final projections = _calculateProjections();
    final finalPoint = projections.last;
    final totalEffort = finalPoint.savingsEffort;
    final limitReachedYear = _findLimitReachedYear(projections);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards
          Row(
            children: [
              Expanded(
                child: _buildKPI(
                  "Capital Final",
                  finalPoint.totalBalance,
                  const Color(0xFF0D71EE),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPI(
                  "Effort Épargne",
                  totalEffort,
                  isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPI(
                  "Gains Totaux",
                  finalPoint.totalInterests,
                  Colors.green,
                ),
              ),
            ],
          ),

          if (limitReachedYear != null) ...[
            const SizedBox(height: 16),
            _buildInfo(
              limitReachedYear == 0
                  ? "Plafond des versements (150 000 €) déjà atteint."
                  : "Plafond des versements (150 000 €) atteint au bout de $limitReachedYear ans.",
            ),
          ],

          const SizedBox(height: 32),

          // Chart
          SizedBox(height: 250, child: _buildChart(projections)),

          const SizedBox(height: 32),

          // Controls
          _buildSectionTitle("PARAMÈTRES DE PROJECTION"),
          _buildSliderControl(
            label: "Versement mensuel (DCA)",
            value: _monthlyContribution,
            controller: _dcaController,
            min: 0,
            max: 5000,
            divisions: 100,
            suffix: "€",
            onChanged: (val) {
              setState(() => _monthlyContribution = val);
              _dcaController.text = val.toStringAsFixed(0);
            },
          ),
          _buildSliderControl(
            label: "Taux annuel estimé",
            value: _annualRate,
            controller: _rateController,
            min: 0.1,
            max: 15.0,
            divisions: 149,
            suffix: "%",
            onChanged: (val) {
              setState(() => _annualRate = val);
              _rateController.text = val.toStringAsFixed(1);
            },
          ),
          _buildSliderControl(
            label: "Horizon (années)",
            value: _horizonYears.toDouble(),
            controller: _horizonController,
            min: 1,
            max: 40,
            divisions: 39,
            suffix: "ans",
            onChanged: (val) {
              setState(() => _horizonYears = val.toInt());
              _horizonController.text = val.toInt().toString();
            },
          ),

          const SizedBox(height: 24),

          _buildSectionTitle("ÉTAT INITIAL"),
          Row(
            children: [
              Expanded(
                child: _buildNumericInput(
                  "Apports réels (€)",
                  _depositsController,
                  (val) => setState(() => _pastDeposits = val),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumericInput(
                  "PnL actuel (€)",
                  _pnlController,
                  (val) => setState(() => _pastPnL = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _resetToReal,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Réinitialiser aux valeurs réelles"),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0D71EE),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildKPI(String label, double value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : Colors.black45,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              _formatter.format(value),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<InvestmentProjectionPoint> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = const Color(0xFF0D71EE);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (val) => FlLine(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: max(1.0, _horizonYears / 5),
              getTitlesWidget: (val, meta) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "${val.toInt()}a",
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (val, meta) {
                if (val == 0) return const SizedBox();
                return Text(
                  val >= 1000000
                      ? "${(val / 1000000).toStringAsFixed(1)}M"
                      : "${(val / 1000).toInt()}k",
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Gains (PnL + Interests) - Layer on top
          LineChartBarData(
            spots: data
                .map((p) => FlSpot(p.year.toDouble(), p.totalBalance))
                .toList(),
            isCurved: true,
            color: Colors.green,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withValues(alpha: 0.2),
            ),
          ),
          // Savings Effort - Bottom layer
          LineChartBarData(
            spots: data
                .map((p) => FlSpot(p.year.toDouble(), p.savingsEffort))
                .toList(),
            isCurved: true,
            color: accentColor,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: accentColor.withValues(alpha: 0.2),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          verticalLines: [
            if (_horizonYears >= 5)
              VerticalLine(
                x: 5,
                color: Colors.orange.withValues(alpha: 0.5),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            if (_horizonYears >= 8)
              VerticalLine(
                x: 8,
                color: Colors.red.withValues(alpha: 0.5),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderControl({
    required String label,
    required double value,
    required TextEditingController controller,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: Color(0xFF0D71EE),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  suffixText: " $suffix",
                  border: InputBorder.none,
                ),
                onSubmitted: (val) {
                  final d = double.tryParse(val.replaceAll(',', '.'));
                  if (d != null && d >= min && d <= max) {
                    onChanged(d);
                  } else {
                    controller.text = value % 1 == 0
                        ? value.toInt().toString()
                        : value.toStringAsFixed(1);
                  }
                },
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: const Color(0xFF0D71EE),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildNumericInput(
    String label,
    TextEditingController controller,
    ValueChanged<double> onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black45,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
          ],
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.02),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (val) {
            final double? d = double.tryParse(val.replaceAll(',', '.'));
            if (d != null) onChanged(d);
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfo(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D71EE).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0D71EE).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF0D71EE),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF0D71EE),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
