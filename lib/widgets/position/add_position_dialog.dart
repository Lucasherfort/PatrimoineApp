import 'package:flutter/material.dart';
import '../../models/investment_position.dart';
import '../../models/position.dart';
import '../../services/position_service.dart';

class AddPositionDialog extends StatefulWidget {
  final Function(Position position, double quantity, double pru) onAdd;
  final List<InvestmentPosition> existingPositions;

  const AddPositionDialog({
    super.key,
    required this.onAdd,
    required this.existingPositions,
  });

  @override
  State<AddPositionDialog> createState() => _AddPositionDialogState();
}

class _AddPositionDialogState extends State<AddPositionDialog> {
  final List<Position> _availablePositions = [];
  List<Position> _filteredPositions = [];
  Position? _selectedPosition;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _pruController = TextEditingController();

  static const Color colorPurple = Color(0xFF9C27B0);

  @override
  void initState() {
    super.initState();
    _loadAvailablePositions();
    _searchController.addListener(_applyFilter);
    _quantityController.addListener(() => setState(() {}));
    _pruController.addListener(() => setState(() {}));
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

      final query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        filtered = filtered.where((p) {
          return p.name.toLowerCase().contains(query) ||
              p.isin.toLowerCase().contains(query);
        }).toList();
      }

      _filteredPositions = filtered;
    });
  }

  bool _isPositionAlreadyInAccount(Position position) {
    return widget.existingPositions.any(
      (investPos) => investPos.positionId == position.id,
    );
  }

  Future<void> _handleAdd() async {
    if (_selectedPosition == null) {
      _showSnack('Veuillez sélectionner une position');
      return;
    }

    if (_isPositionAlreadyInAccount(_selectedPosition!)) {
      _showSnack(
        'Cette position (${_selectedPosition!.isin}) existe déjà dans ce compte',
      );
      return;
    }

    final quantity = double.tryParse(
      _quantityController.text.replaceAll(',', '.'),
    );
    final pru = double.tryParse(_pruController.text.replaceAll(',', '.'));

    if (quantity == null || quantity <= 0) {
      _showSnack('Quantité invalide');
      return;
    }

    if (pru == null || pru <= 0) {
      _showSnack('PRU invalide');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onAdd(_selectedPosition!, quantity, pru);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack('Erreur lors de l\'ajout');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: colorPurple),
                      )
                    : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white54),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildMainContent(context),
                      ),
              ),
              // Bloc de configuration + Bouton Valider
              if (_selectedPosition != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [_buildInputs(context), _buildFooter(context)],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajouter une position',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Recherchez et configurez votre investissement",
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.black45,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildSearchField(context),
          const SizedBox(height: 24),
          Text(
            "RÉSULTATS",
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildPositionList(context),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return TextField(
      controller: _searchController,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: 'Rechercher par nom ou ISIN...',
        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
        prefixIcon: const Icon(Icons.search, color: colorPurple),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: isDark
              ? BorderSide.none
              : BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
    );
  }

  Widget _buildPositionList(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (_filteredPositions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Aucune position trouvée',
            style: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredPositions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final position = _filteredPositions[index];
        final isSelected = position == _selectedPosition;
        final isAlreadyInAccount = _isPositionAlreadyInAccount(position);

        return InkWell(
          onTap: isAlreadyInAccount
              ? null
              : () {
                  setState(() {
                    _selectedPosition = position;
                    _pruController.text = position.price
                        .toStringAsFixed(2)
                        .replaceAll('.', ',');
                  });
                },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorPurple.withValues(alpha: 0.1)
                  : theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? colorPurple
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05)),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            position.isin,
                            style: const TextStyle(
                              color: colorPurple,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              position.type.toUpperCase(),
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        position.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isAlreadyInAccount
                              ? (isDark ? Colors.white24 : Colors.black26)
                              : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (isAlreadyInAccount)
                        const Text(
                          'Déjà possédé dans ce compte',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: colorPurple)
                else
                  Text(
                    "${position.price.toStringAsFixed(2)} €",
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputs(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "CONFIGURATION : ${_selectedPosition!.isin}",
            style: const TextStyle(
              color: colorPurple,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildConfigField(
                  context: context,
                  label: "Quantité",
                  controller: _quantityController,
                  icon: Icons.pie_chart_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildConfigField(
                  context: context,
                  label: "PRU (€)",
                  controller: _pruController,
                  icon: Icons.euro_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          color: theme.textTheme.bodyLarge?.color,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 12,
          ),
          border: InputBorder.none,
          icon: Icon(icon, color: colorPurple, size: 18),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final quantity = double.tryParse(
      _quantityController.text.replaceAll(',', '.'),
    );
    final pru = double.tryParse(_pruController.text.replaceAll(',', '.'));
    final bool isFormValid =
        _selectedPosition != null &&
        quantity != null &&
        quantity > 0 &&
        pru != null &&
        pru > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ElevatedButton(
        onPressed: (isFormValid && !_isSaving) ? _handleAdd : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPurple,
          disabledBackgroundColor: isDark
              ? colorPurple.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          foregroundColor: Colors.white,
          disabledForegroundColor: isDark ? Colors.white24 : Colors.black26,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'VALIDER',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
      ),
    );
  }
}
