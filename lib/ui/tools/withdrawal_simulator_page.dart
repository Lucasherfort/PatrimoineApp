import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../../services/patrimoine_service.dart';
import '../../services/financial_profile_manager.dart';
import '../../services/settings_service.dart';

class WithdrawalSimulatorPage extends StatefulWidget {
  const WithdrawalSimulatorPage({super.key});

  @override
  State<WithdrawalSimulatorPage> createState() =>
      _WithdrawalSimulatorPageState();
}

class _WithdrawalSimulatorPageState extends State<WithdrawalSimulatorPage> {
  static const Color colorPrimary = Color(0xFF0D71EE);
  static const Color colorSuccess = Color(0xFF10B981);

  bool _isLoading = true;
  double _basePatrimoine = 0.0;
  double _monthlyInv = 500.0;

  double _initialCapital = 200000.0;
  late TextEditingController _initialCapitalController;

  double _startAge = 50.0;
  final double _currentAgeBaseline = 30.0; // Âge actuel estimé de référence
  double _durationYears = 30.0;

  bool _isPercentageMode = true; // true = %, false = somme fixe
  double _withdrawalRate = 4.0; // 4% par an
  double _fixedAnnualWithdrawal = 24000.0; // 2000 € / mois

  double _annualReturnRate = 5.0; // 5% par an

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _initialCapitalController = TextEditingController(
      text: _initialCapital.toStringAsFixed(0),
    );
    _loadBaseDataAndCalculate();
  }

  @override
  void dispose() {
    _initialCapitalController.dispose();
    super.dispose();
  }

  Future<void> _loadBaseDataAndCalculate() async {
    try {
      final patrimoineService = PatrimoineService();
      final profileManager = FinancialProfileManager();
      final settingsService = SettingsService();

      final totalPatrimoine = await patrimoineService.getPatrimoineGross();
      double? monthlyInv = await settingsService.getMonthlyInvestment();
      if ((monthlyInv ?? 0.0) <= 0) {
        monthlyInv = profileManager.monthlyInvestment;
      }
      if ((monthlyInv ?? 0.0) <= 0) {
        monthlyInv = await patrimoineService
            .calculateEstimatedMonthlyInvestment();
      }
      if ((monthlyInv ?? 0.0) <= 0) {
        monthlyInv = 500.0;
      }

      setState(() {
        _basePatrimoine = totalPatrimoine > 0 ? totalPatrimoine : 10000.0;
        _monthlyInv = monthlyInv!;
        _recalculateInitialCapitalForAge(_startAge);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _basePatrimoine = 50000.0;
        _monthlyInv = 500.0;
        _recalculateInitialCapitalForAge(_startAge);
        _isLoading = false;
      });
    }
  }

  void _recalculateInitialCapitalForAge(double targetAge) {
    final int accumulationYears = (targetAge - _currentAgeBaseline)
        .clamp(1, 60)
        .round();
    const double compoundRate = 7.0; // 7% annuel composé
    double futureValue = _basePatrimoine;
    double monthlyRate = compoundRate / 100 / 12;

    for (int m = 1; m <= accumulationYears * 12; m++) {
      futureValue = (futureValue + _monthlyInv) * (1 + monthlyRate);
    }

    _initialCapital = futureValue;
    _initialCapitalController.text = _initialCapital.toStringAsFixed(0);
  }

  Map<String, dynamic> _calculateResults() {
    final int years = _durationYears.round();
    final double returnRate = _annualReturnRate / 100;

    double currentCapital = _initialCapital;
    double totalWithdrawn = 0.0;
    int? depletionYear;

    final List<Map<String, dynamic>> yearlyData = [];
    yearlyData.add({
      'age': _startAge.round(),
      'capital': currentCapital,
      'withdrawn': 0.0,
    });

    for (int i = 1; i <= years; i++) {
      final int currentAge = (_startAge + i).round();
      if (currentCapital <= 0) {
        depletionYear ??= currentAge;
        yearlyData.add({'age': currentAge, 'capital': 0.0, 'withdrawn': 0.0});
        continue;
      }

      double withdrawal = _isPercentageMode
          ? currentCapital * (_withdrawalRate / 100)
          : _fixedAnnualWithdrawal;

      if (withdrawal > currentCapital) {
        withdrawal = currentCapital;
      }

      totalWithdrawn += withdrawal;
      currentCapital -= withdrawal;

      if (currentCapital > 0) {
        currentCapital *= (1 + returnRate);
      }

      if (currentCapital <= 0 && depletionYear == null) {
        depletionYear = currentAge;
        currentCapital = 0.0;
      }

      yearlyData.add({
        'age': currentAge,
        'capital': currentCapital,
        'withdrawn': withdrawal,
      });
    }

    return {
      'finalCapital': currentCapital,
      'totalWithdrawn': totalWithdrawn,
      'depletionAge': depletionYear,
      'yearlyData': yearlyData,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final results = _calculateResults();
    final double finalCapital = results['finalCapital'];
    final int? depletionAge = results['depletionAge'];
    final List<Map<String, dynamic>> yearlyData = results['yearlyData'];

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Simulateur de Retrait (Décaissement)",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: colorPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HERO CARD ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.04,
                          ),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "CAPITAL RESTANT FINAL",
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black45,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (depletionAge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Épuisé à l'âge de $depletionAge ans",
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorSuccess.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "Capital pérenne",
                                  style: TextStyle(
                                    color: colorSuccess,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _currency.format(finalCapital),
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- CHART ---
                  Container(
                    height: 220,
                    padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            "Évolution du capital restant",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(child: _buildChart(yearlyData)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- PARAMETERS CARD ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Paramètres de décaissement",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Slider Start Age (dynamically updates initial capital)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Âge de départ",
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            Text(
                              "${_startAge.round()} ans",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorPrimary,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _startAge,
                          min: 40,
                          max: 80,
                          divisions: 40,
                          activeColor: colorPrimary,
                          onChanged: (val) {
                            setState(() {
                              _startAge = val;
                              _recalculateInitialCapitalForAge(_startAge);
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        // Capital initial editable field
                        TextField(
                          controller: _initialCapitalController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                "Capital initial à ${_startAge.round()} ans (projeté)",
                            suffixText: "€",
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.black.withValues(alpha: 0.02),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _initialCapital =
                                  double.tryParse(val.replaceAll(',', '.')) ??
                                  0.0;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // Mode Selector Segmented / Switch
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text("Règle en %")),
                                selected: _isPercentageMode,
                                onSelected: (val) =>
                                    setState(() => _isPercentageMode = true),
                                selectedColor: colorPrimary.withValues(
                                  alpha: 0.2,
                                ),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isPercentageMode
                                      ? colorPrimary
                                      : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text("Somme fixe")),
                                selected: !_isPercentageMode,
                                onSelected: (val) =>
                                    setState(() => _isPercentageMode = false),
                                selectedColor: colorPrimary.withValues(
                                  alpha: 0.2,
                                ),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: !_isPercentageMode
                                      ? colorPrimary
                                      : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_isPercentageMode) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Taux de retrait annuel",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                              Text(
                                "${_withdrawalRate.toStringAsFixed(1)} %",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorPrimary,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _withdrawalRate,
                            min: 1.0,
                            max: 10.0,
                            divisions: 18,
                            activeColor: colorPrimary,
                            onChanged: (val) =>
                                setState(() => _withdrawalRate = val),
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Retrait annuel fixe",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                              Text(
                                _currency.format(_fixedAnnualWithdrawal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorPrimary,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _fixedAnnualWithdrawal,
                            min: 5000,
                            max: 100000,
                            divisions: 95,
                            activeColor: colorPrimary,
                            onChanged: (val) =>
                                setState(() => _fixedAnnualWithdrawal = val),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Slider Duration
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Durée de décaissement",
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            Text(
                              "${_durationYears.round()} ans",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorPrimary,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _durationYears,
                          min: 5,
                          max: 50,
                          divisions: 45,
                          activeColor: colorPrimary,
                          onChanged: (val) =>
                              setState(() => _durationYears = val),
                        ),

                        const SizedBox(height: 12),

                        // Slider Annual Return Rate
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Rendement du reste investi",
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            Text(
                              "${_annualReturnRate.toStringAsFixed(1)} %",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorSuccess,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _annualReturnRate,
                          min: 0.0,
                          max: 12.0,
                          divisions: 24,
                          activeColor: colorSuccess,
                          onChanged: (val) =>
                              setState(() => _annualReturnRate = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
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
                isDark ? const Color(0xFF334155) : Colors.white,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                return LineTooltipItem(
                  "Âge ${flSpot.x.toInt()} ans\n",
                  TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  children: [
                    TextSpan(
                      text: "Capital : ${_currency.format(flSpot.y)}",
                      style: const TextStyle(
                        color: colorPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (val) => FlLine(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
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
              interval: max(1.0, _durationYears / 5),
              getTitlesWidget: (val, meta) => Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  "${val.toInt()}a",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (val, meta) {
                if (val == 0) return const SizedBox();
                return Text(
                  val >= 1000000
                      ? "${(val / 1000000).toStringAsFixed(1)}M"
                      : "${(val / 1000).toInt()}k",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data
                .map(
                  (p) => FlSpot(
                    (p['age'] as int).toDouble(),
                    p['capital'] as double,
                  ),
                )
                .toList(),
            isCurved: true,
            color: colorPrimary,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorPrimary.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
