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
  List<Position> _filteredPositions = [];
  Position? _selectedPosition;

  bool _isLoading = true;
  String? _errorMessage;

  String _filterType = 'Toutes';

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _pruController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAvailablePositions();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _pruController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailablePositions() async {
    try {
      final positions = await PositionService().getAllPositions();
      setState(() {
        _availablePositions.addAll(positions);
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des positions';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      var filtered = _availablePositions;

      if (_filterType != 'Toutes') {
        filtered = filtered.where((p) => p.type == _filterType).toList();
      }

      final query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        filtered = filtered.where((p) {
          return p.name.toLowerCase().contains(query) ||
              p.ticker.toLowerCase().contains(query);
        }).toList();
      }

      _filteredPositions = filtered;

      if (!_filteredPositions.contains(_selectedPosition)) {
        _selectedPosition = null;
      }
    });
  }

  void _handleAdd() {
    if (_selectedPosition == null) {
      _showSnack('Veuillez sélectionner une position');
      return;
    }

    final quantity =
    double.tryParse(_quantityController.text.replaceAll(',', '.'));
    final pru =
    double.tryParse(_pruController.text.replaceAll(',', '.'));

    if (quantity == null || quantity <= 0) {
      _showSnack('Quantité invalide');
      return;
    }

    if (pru == null || pru <= 0) {
      _showSnack('PRU invalide');
      return;
    }

    widget.onAdd(_selectedPosition!, quantity, pru);
    Navigator.pop(context);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          children: [
            _buildHeader(),

            /// CONTENU
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(color: Colors.purple),
              )
                  : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilters(),
                    const SizedBox(height: 16),
                    _buildSearch(),
                    const SizedBox(height: 16),
                    _buildTitle(),
                    const SizedBox(height: 8),

                    /// ✅ LISTE SCROLLABLE UNIQUEMENT
                    Expanded(child: _buildPositionList()),

                    const SizedBox(height: 20),
                    _buildInputs(),
                  ],
                ),
              ),
            ),

            _buildFooter(),
          ],
        ),
      ),
    );
  }

  /// ---------- UI PARTS ----------

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade700, Colors.purple.shade900],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_chart_rounded, color: Colors.white),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Ajouter une position',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(child: _buildFilterChip('Toutes', Icons.all_inclusive)),
        const SizedBox(width: 8),
        Expanded(child: _buildFilterChip('Action', Icons.show_chart)),
        const SizedBox(width: 8),
        Expanded(child: _buildFilterChip('ETF', Icons.pie_chart)),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Rechercher',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear),
          onPressed: _searchController.clear,
        )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Sélectionner une position',
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildPositionList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _filteredPositions.isEmpty
          ? const Center(child: Text('Aucune position trouvée'))
          : ListView.separated(
        itemCount: _filteredPositions.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final position = _filteredPositions[index];
          final isSelected = position == _selectedPosition;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedPosition = position;
                _pruController.text =
                    position.price.toStringAsFixed(2).replaceAll('.', ',');
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              color: isSelected
                  ? Colors.purple.shade50
                  : Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${position.name} (${position.ticker})',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.purple
                            : Colors.black87,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle,
                        color: Colors.purple),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputs() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _quantityController,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Quantité',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _pruController,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'PRU',
              suffixText: '€',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        borderRadius:
        const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _handleAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Ajouter',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, IconData icon) {
    final isSelected = _filterType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _filterType = type;
          _applyFilter();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
