import 'package:flutter/material.dart';
import '../../models/position.dart';
import '../../services/position_service.dart';

class AddPositionDialog extends StatefulWidget {
  final Function(Position position, double quantity, double pru) onAdd;

  const AddPositionDialog({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddPositionDialog> createState() => _AddPositionDialogState();
}

class _AddPositionDialogState extends State<AddPositionDialog> {
  final List<Position> _availablePositions = [];
  Position? _selectedPosition;
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _pruController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAvailablePositions();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _pruController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailablePositions() async {
    try {
      final positions = await PositionService().getAllPositions();
      setState(() {
        _availablePositions.addAll(positions);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des positions';
        _isLoading = false;
      });
    }
  }

  void _handleAdd() {
    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une position')),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text.replaceAll(',', '.'));
    final pru = double.tryParse(_pruController.text.replaceAll(',', '.'));

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

    widget.onAdd(_selectedPosition!, quantity, pru);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ))
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ),
              )
            else ...[
                // Dropdown pour sélectionner la position
                DropdownButtonFormField<Position>(
                  decoration: const InputDecoration(
                    labelText: 'Sélectionner une position',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  initialValue: _selectedPosition,
                  isExpanded: true,
                  items: _availablePositions.map((position) {
                    return DropdownMenuItem(
                      value: position,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            position.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            position.ticker,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPosition = value;

                      // Si la position a un cours actuel, on le met dans le champ PRU
                      if (_selectedPosition != null)
                      {
                        _pruController.text = _selectedPosition!.price.toStringAsFixed(2).replaceAll('.', ',');
                      }
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