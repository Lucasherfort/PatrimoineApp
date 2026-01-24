import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatrimoineHeader extends StatefulWidget {
  final double patrimoineTotal;
  final double totalDepose;
  final VoidCallback? onRefresh;

  const PatrimoineHeader({
    super.key,
    required this.patrimoineTotal,
    required this.totalDepose,
    this.onRefresh,
  });

  @override
  State<PatrimoineHeader> createState() => _PatrimoineHeaderState();
}

class _PatrimoineHeaderState extends State<PatrimoineHeader> {
  bool _isVisible = true;

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(amount).trim();
  }

  double get _gains => widget.patrimoineTotal - widget.totalDepose;

  double get _gainsPercentage {
    if (widget.totalDepose == 0) return 0;
    return (_gains / widget.totalDepose) * 100;
  }

  Color get _gainsColor {
    if (_gains > 0) return Colors.green.shade600;
    if (_gains < 0) return Colors.red.shade600;
    return Colors.blueGrey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.purple.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.shade200.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Section patrimoine total ─────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 14,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Mon patrimoine",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isVisible
                            ? Text(
                          "${_formatAmount(widget.patrimoineTotal)} €",
                          key: const ValueKey('visible'),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.blue.shade900,
                            letterSpacing: -0.5,
                          ),
                        )
                            : Text(
                          "• • • • • •",
                          key: const ValueKey('hidden'),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: Colors.blue.shade300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (widget.onRefresh != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onRefresh,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.refresh_rounded,
                              size: 20,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() => _isVisible = !_isVisible);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            _isVisible
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            size: 20,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Divider ─────────────────────────────────────
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade200.withValues(alpha: 0),
                  Colors.blue.shade200,
                  Colors.blue.shade200.withValues(alpha: 0),
                ],
              ),
            ),
          ),

          // ─── Section gains ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _gainsColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plus/moins-value',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              _gains >= 0
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 14,
                              color: _gainsColor,
                            ),
                            const SizedBox(width: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _isVisible
                                  ? Text(
                                "${_gains >= 0 ? '+' : ''}${_formatAmount(_gains)} €",
                                key: const ValueKey('gains-visible'),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _gainsColor,
                                ),
                              )
                                  : Text(
                                "• • • •",
                                key: const ValueKey('gains-hidden'),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isVisible
                      ? Container(
                    key: const ValueKey('percent-visible'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _gainsColor.withValues(alpha: 0.12),
                      border: Border(
                        left: BorderSide(
                          color: _gainsColor,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      "${_gainsPercentage >= 0 ? '+' : ''}${_gainsPercentage.toStringAsFixed(2)}%",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: _gainsColor,
                      ),
                    ),
                  )
                      : Container(
                    key: const ValueKey('percent-hidden'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      "• •",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}