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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox();
    if (_assets.isEmpty) return const SizedBox();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            "IMMOBILIER",
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
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
