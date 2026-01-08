import 'package:flutter/material.dart';
import '../services/google_sheet_service.dart';

class AddPositionDialog extends StatefulWidget {
  final Function(String ticker, String name, double quantity, double pru) onAdd;

  const AddPositionDialog({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddPositionDialog> createState() => _AddPositionDialogState();
}

class _AddPositionDialogState extends State<AddPositionDialog> {
  final GoogleSheetsService _sheetsService = GoogleSheetsService();

  List<Map<String, dynamic>> _availableEtfs = [];
  Map<String, dynamic>? _selectedEtf;
  bool _isLoadingEtfs = true;
  String? _errorMessage;

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _pruController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAvailableEtfs();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _pruController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableEtfs() async {
    try {
      final etfs = await _sheetsService.fetchEtfs();
      setState(() {
        _availableEtfs = etfs;
        _isLoadingEtfs = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des ETFs: $e';
        _isLoadingEtfs = false;
      });
    }
  }

  void _handleAdd() {
    if (_selectedEtf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un ETF')),
      );
      return;
    }

    final quantity = double.tryParse(
      _quantityController.text.replaceAll(',', '.'),
    );
    final pru = double.tryParse(
      _pruController.text.replaceAll(',', '.'),
    );

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantité invalide')),
      );
      return;
    }

    if (pru == null || pru <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PRU invalide')),
      );
      return;
    }

    final ticker = _selectedEtf!['ticker']?.toString() ?? '';
    final name = _selectedEtf!['name']?.toString() ?? ticker;

    widget.onAdd(ticker, name, quantity, pru);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ajouter une position',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_isLoadingEtfs)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
                // Sélection de l'ETF
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: const InputDecoration(
                    labelText: 'Sélectionner un ETF',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  initialValue: _selectedEtf,
                  isExpanded: true,
                  items: _availableEtfs.map((etf) {
                    final ticker = etf['ticker']?.toString() ?? '';
                    final name = etf['name']?.toString() ?? ticker;
                    return DropdownMenuItem(
                      value: etf,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ticker,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedEtf = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Quantité
                TextField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Quantité',
                    border: OutlineInputBorder(),
                    helperText: 'Nombre d\'actions/parts',
                  ),
                ),
                const SizedBox(height: 16),

                // PRU
                TextField(
                  controller: _pruController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Prix de Revient Unitaire (PRU)',
                    suffixText: '€',
                    border: OutlineInputBorder(),
                    helperText: 'Prix moyen d\'achat par unité',
                  ),
                ),
                const SizedBox(height: 24),

                // Boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _handleAdd,
                      child: const Text('Ajouter'),
                    ),
                  ],
                ),
              ],
          ],
        ),
      ),
    );
  }
}