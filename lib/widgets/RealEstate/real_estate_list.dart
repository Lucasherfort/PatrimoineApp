import 'package:flutter/material.dart';
import '../../models/patrimoine/real_estate_asset.dart';
import '../../services/real_estate_service.dart';
import 'real_estate_asset_card.dart';

class RealEstateList extends StatefulWidget {
  final VoidCallback? onAssetUpdated;

  const RealEstateList({super.key, this.onAssetUpdated});

  @override
  State<RealEstateList> createState() => _RealEstateListState();
}

class _RealEstateListState extends State<RealEstateList> {
  final RealEstateService _service = RealEstateService();
  List<RealEstateAsset> _assets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);
    try {
      final assets = await _service.getUserRealEstateAssets();
      setState(() {
        _assets = assets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}\u00A0',
    );
    return '$intPart,${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox();
    if (_assets.isEmpty) return const SizedBox();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalRealEstate = _assets.fold<double>(0, (sum, a) => sum + a.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade400.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.home_work_rounded,
                  color: isDark
                      ? Colors.orange.shade300
                      : Colors.orange.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Immobilier",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              if (_assets.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.orange.shade400.withValues(alpha: 0.15)
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.shade400.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_formatAmount(totalRealEstate)} €',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.orange.shade300
                          : Colors.orange.shade800,
                    ),
                  ),
                ),
            ],
          ),
        ),
        ..._assets.map(
          (asset) => RealEstateAssetCard(
            asset: asset,
            onUpdated: () {
              _loadAssets();
              widget.onAssetUpdated?.call();
            },
            onDeleted: () async {
              await _service.deleteAsset(asset.id);
              _loadAssets();
              widget.onAssetUpdated?.call();
            },
          ),
        ),
      ],
    );
  }
}
