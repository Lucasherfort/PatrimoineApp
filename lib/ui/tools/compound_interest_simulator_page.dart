import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../../services/financial_profile_manager.dart';
import '../../services/patrimoine_service.dart';
import '../../services/settings_service.dart';

class CompoundInterestSimulatorPage extends StatefulWidget {
  const CompoundInterestSimulatorPage({super.key});

  @override
  State<CompoundInterestSimulatorPage> createState() =>
      _CompoundInterestSimulatorPageState();
}

class _CompoundInterestSimulatorPageState
    extends State<CompoundInterestSimulatorPage> {
  static const Color colorBlue = Color(0xFF0D71EE);
  static const Color colorGreen = Color(0xFF10B981);

  bool _isLoading = true;
  double _initialCapital = 0.0;
  double _monthlyContribution = 0.0;
  double _years = 20.0;
  double _annualRate = 7.0; // 7% par an

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadInitialValues();
  }

  Future<void> _loadInitialValues() async {
    try {
      final patrimoineService = PatrimoineService();
      final profileManager = FinancialProfileManager();
      final settingsService = SettingsService();

      final totalPatrimoine = await patrimoineService.getPatrimoineGross();

      double? monthlyInv = await settingsService.getMonthlyInvestment();
      if (monthlyInv == null || monthlyInv <= 0) {
        monthlyInv = profileManager.monthlyInvestment;
      }
      if (monthlyInv <= 0) {
        monthlyInv = await patrimoineService
            .calculateEstimatedMonthlyInvestment();
      }
      if (monthlyInv <= 0) {
        monthlyInv = 500.0;
      }

      setState(() {
        _initialCapital = totalPatrimoine;
        _monthlyContribution = monthlyInv!;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _initialCapital = 5000.0;
        _monthlyContribution = 500.0;
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _calculateResults() {
    final int totalMonths = (_years * 12).round();
    final double monthlyRate = _annualRate / 100 / 12;

    double futureValue = _initialCapital;
    double totalContributed = _initialCapital;

    final List<Map<String, dynamic>> yearlyBreakdown = [];
    yearlyBreakdown.add({
      'year': 0,
      'futureValue': futureValue,
      'totalContributed': totalContributed,
      'interestEarned': 0.0,
    });

    for (int m = 1; m <= totalMonths; m++) {
      if (monthlyRate > 0) {
        futureValue = (futureValue + _monthlyContribution) * (1 + monthlyRate);
      } else {
        futureValue += _monthlyContribution;
      }
      totalContributed += _monthlyContribution;

      if (m % 12 == 0 || m == totalMonths) {
        final int year = (m / 12).ceil();
        final double interestEarned = futureValue - totalContributed;
        yearlyBreakdown.add({
          'year': year,
          'futureValue': futureValue,
          'totalContributed': totalContributed,
          'interestEarned': interestEarned,
        });
      }
    }

    final double finalValue = futureValue;
    final double totalInterest = finalValue - totalContributed;

    return {
      'finalValue': finalValue,
      'totalContributed': totalContributed,
      'totalInterest': totalInterest,
      'yearlyBreakdown': yearlyBreakdown,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final results = _calculateResults();
    final double finalValue = results['finalValue'];
    final double totalContributed = results['totalContributed'];
    final double totalInterest = results['totalInterest'];
    final List<Map<String, dynamic>> breakdown = results['yearlyBreakdown'];

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF060B26)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Intérêts Composés",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        toolbarHeight: 40,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- COMPACT HEADER SUMMARY BAR ---
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF1E3A8A),
                                  const Color(0xFF0D71EE),
                                ]
                              : [
                                  const Color(0xFF0D71EE),
                                  const Color(0xFF3B82F6),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCompactSummaryItem(
                            "Capital Final",
                            _currency.format(finalValue),
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: Colors.white24,
                          ),
                          _buildCompactSummaryItem(
                            "Versé",
                            _currency.format(totalContributed),
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: Colors.white24,
                          ),
                          _buildCompactSummaryItem(
                            "Intérêts",
                            _currency.format(totalInterest),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // --- COMPACT CHART ---
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: _glassDecoration(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Projection",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Row(
                                  children: [
                                    _buildLegendIndicator("Total", colorGreen),
                                    const SizedBox(width: 8),
                                    _buildLegendIndicator("Versé", colorBlue),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(child: _buildChart(breakdown)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // --- COMPACT PARAMETERS ---
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: _glassDecoration(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Patrimoine initial: ${_currency.format(_initialCapital)}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  "Mensuel: ${_currency.format(_monthlyContribution)}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Slider Durée
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Durée : ${_years.round()} ans",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 28,
                              child: Slider(
                                value: _years,
                                min: 1,
                                max: 40,
                                divisions: 39,
                                activeColor: colorBlue,
                                onChanged: (val) =>
                                    setState(() => _years = val),
                              ),
                            ),
                            // Slider Taux
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Rendement annuel : ${_annualRate.toStringAsFixed(1)} %",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 28,
                              child: Slider(
                                value: _annualRate,
                                min: 1.0,
                                max: 15.0,
                                divisions: 28,
                                activeColor: colorGreen,
                                onChanged: (val) =>
                                    setState(() => _annualRate = val),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCompactSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (LineBarSpot touchedSpot) =>
                isDark ? const Color(0xFF1E293B) : Colors.white,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                if (flSpot.barIndex == 0) {
                  return LineTooltipItem(
                    "Année ${flSpot.x.toInt()}\n",
                    TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    children: [
                      TextSpan(
                        text: "Total: ${_currency.format(flSpot.y)}",
                        style: const TextStyle(
                          color: colorGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                } else {
                  return LineTooltipItem(
                    "Versé: ${_currency.format(flSpot.y)}",
                    TextStyle(
                      color: colorBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  );
                }
              }).toList();
            },
          ),
        ),
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
              interval: max(1.0, _years / 4),
              getTitlesWidget: (val, meta) => Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "${val.toInt()}a",
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (val, meta) {
                if (val == 0) return const SizedBox();
                return Text(
                  val >= 1000000
                      ? "${(val / 1000000).toStringAsFixed(1)}M"
                      : "${(val / 1000).toInt()}k",
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Total with interest (Green)
          LineChartBarData(
            spots: data
                .map(
                  (p) => FlSpot(
                    (p['year'] as int).toDouble(),
                    p['futureValue'] as double,
                  ),
                )
                .toList(),
            isCurved: true,
            color: colorGreen,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorGreen.withValues(alpha: 0.15),
            ),
          ),
          // Total contributed / Versé (Blue)
          LineChartBarData(
            spots: data
                .map(
                  (p) => FlSpot(
                    (p['year'] as int).toDouble(),
                    p['totalContributed'] as double,
                  ),
                )
                .toList(),
            isCurved: true,
            color: colorBlue,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorBlue.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  BoxDecoration _glassDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
      ),
    );
  }
}
