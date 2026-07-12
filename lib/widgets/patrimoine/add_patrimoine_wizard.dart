import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../bdd/investment_source_table.dart';
import '../../bdd/liquidity_source_table.dart';
import '../../bdd/savings_source_table.dart';
import '../../bdd/user_investment_account_table.dart';
import '../../bdd/user_liquidity_account_table.dart';
import '../../bdd/user_savings_account_table.dart';
import '../../models/patrimoine/patrimoine_category.dart';
import '../../models/source_item.dart';
import '../../models/bank.dart';
import '../../services/patrimoine_wizard_service.dart';

class AddPatrimoineWizard extends StatefulWidget {
  const AddPatrimoineWizard({super.key});

  @override
  State<AddPatrimoineWizard> createState() => _AddPatrimoineWizardState();
}

class _AddPatrimoineWizardState extends State<AddPatrimoineWizard> {
  final PatrimoineWizardService _wizardService = PatrimoineWizardService();
  final TextEditingController _searchController = TextEditingController();

  // Étapes du wizard
  int currentStep = 0;

  // État du wizard
  bool isLoading = true;
  bool isSaving = false;

  // Étape 1 : Catégories
  List<PatrimoineCategory> categories = [];
  PatrimoineCategory? selectedCategory;

  // Étape 2 : Sources
  List<SourceItem> sources = [];
  SourceItem? selectedSource;

  // Étape 3 : Banques
  List<Bank> banks = [];
  List<Bank> filteredBanks = [];
  Bank? selectedBank;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      filteredBanks = banks
          .where(
            (bank) => bank.name.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  Future<void> _loadCategories() async {
    setState(() => isLoading = true);
    try {
      final loadedCategories = await _wizardService.getPatrimoineCategories();
      setState(() {
        categories = loadedCategories;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadSourcesForCategory(PatrimoineCategory category) async {
    setState(() => isLoading = true);
    try {
      final loadedSources = await _wizardService.getSourcesForCategory(
        category,
      );
      setState(() {
        sources = loadedSources;
        selectedSource = null;
        isLoading = false;
        currentStep = 1;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadBanksForSource(SourceItem source) async {
    setState(() => isLoading = true);
    try {
      final loadedBanks = await _loadBanksBySourceType(source);
      // Tri par ordre alphabétique
      loadedBanks.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      setState(() {
        banks = loadedBanks;
        filteredBanks = loadedBanks;
        selectedBank = null;
        isLoading = false;
        currentStep = 2;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Erreur chargement des banques: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _savePatrimoine() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showError('Utilisateur non connecté');
      return;
    }

    setState(() => isSaving = true);

    try {
      if (selectedSource!.type == 'liquidity') {
        final existing = await Supabase.instance.client
            .from(LiquiditySourceTable.tableName)
            .select('id')
            .eq('bank_id', selectedBank!.id)
            .eq('category_id', selectedCategory!.id)
            .eq('liquidity_category_id', selectedSource!.id)
            .maybeSingle();

        if (existing != null) {
          await Supabase.instance.client
              .from(UserLiquidityAccountTable.tableName)
              .insert({
                'user_id': user.id,
                'liquidity_source_id': existing['id'],
                'amount': 0,
              });
        }
      } else if (selectedSource!.type == 'savings') {
        final existing = await Supabase.instance.client
            .from(SavingsSourceTable.tableName)
            .select('id')
            .eq('bank_id', selectedBank!.id)
            .eq('category_id', selectedCategory!.id)
            .eq('savings_category_id', selectedSource!.id)
            .maybeSingle();

        if (existing != null) {
          await Supabase.instance.client
              .from(UserSavingsAccountTable.tableName)
              .insert({
                'user_id': user.id,
                'savings_source_id': existing['id'],
                'principal': 0,
                'interest': 0,
              });
        }
      } else if (selectedSource!.type == 'investment') {
        final existing = await Supabase.instance.client
            .from(InvestmentSourceTable.tableName)
            .select('id')
            .eq('bank_id', selectedBank!.id)
            .eq('category_id', selectedCategory!.id)
            .eq('investment_category_id', selectedSource!.id)
            .maybeSingle();

        if (existing != null) {
          await Supabase.instance.client
              .from(UserInvestmentAccountTable.tableName)
              .insert({
                'user_id': user.id,
                'investment_source_id': existing['id'],
                'total_contribution': 0,
                'cash_balance': 0,
                'amount': 0,
              });
        }
      }

      _showSuccess('Compte créé avec succès');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError('Erreur lors de la création: $e');
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<List<Bank>> _loadBanksBySourceType(SourceItem source) {
    switch (source.type) {
      case 'liquidity':
        return _wizardService.getBanksForLiquiditySource(
          categoryId: selectedCategory!.id,
          liquidityCategoryId: source.id,
        );
      case 'savings':
        return _wizardService.getBanksForSavingsSource(
          categoryId: selectedCategory!.id,
          savingsCategoryId: source.id,
        );
      case 'investment':
        return _wizardService.getBanksForInvestmentSource(
          categoryId: selectedCategory!.id,
          investmentCategoryId: source.id,
        );
      default:
        return Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color colorBlue = Color(0xFF0D71EE);
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildProgressIndicator(),
            const SizedBox(height: 24),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: colorBlue),
                      )
                    : _buildStepContent(context),
              ),
            ),
            const SizedBox(height: 20),
            _buildNavigationButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String title = "Ajouter un compte";
    if (currentStep == 0) title = "Catégorie de patrimoine";
    if (currentStep == 1) title = "Type de compte";
    if (currentStep == 2) title = "Établissement bancaire";

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              if (selectedCategory != null && currentStep > 0)
                Text(
                  selectedCategory!.label,
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
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.close,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final bool isActive = index <= currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF0D71EE)
                  : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white12
                        : Colors.black.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (currentStep) {
      case 0:
        return _buildCategoryGrid(context);
      case 1:
        return _buildSourceList(context);
      case 2:
        return _buildBankSearchableList(context);
      default:
        return const SizedBox();
    }
  }

  Widget _buildCategoryGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final bool isSelected = selectedCategory?.id == category.id;

        IconData icon = Icons.help_outline;
        if (category.name == 'Cash') icon = Icons.euro_rounded;
        if (category.name.contains('Saving')) icon = Icons.savings_rounded;
        if (category.name.contains('Investments')) {
          icon = Icons.trending_up_rounded;
        }

        return _buildSelectionCard(
          context,
          title: category.label,
          icon: icon,
          isSelected: isSelected,
          onTap: () {
            setState(() => selectedCategory = category);
            _loadSourcesForCategory(category);
          },
        );
      },
    );
  }

  Widget _buildSourceList(BuildContext context) {
    return ListView.separated(
      itemCount: sources.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final source = sources[index];
        final bool isSelected = selectedSource?.id == source.id;

        return _buildSelectionTile(
          context,
          title: source.name,
          isSelected: isSelected,
          onTap: () {
            setState(() => selectedSource = source);
            _loadBanksForSource(source);
          },
        );
      },
    );
  }

  Widget _buildBankSearchableList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        TextField(
          controller: _searchController,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: "Rechercher une banque...",
            hintStyle: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filteredBanks.isEmpty
              ? Center(
                  child: Text(
                    "Aucune banque trouvée",
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black26,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: filteredBanks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final bank = filteredBanks[index];
                    final bool isSelected = selectedBank?.id == bank.id;
                    return _buildSelectionTile(
                      context,
                      title: bank.name,
                      isSelected: isSelected,
                      compact: true,
                      logoUrl: bank.logoUrl,
                      onTap: () => setState(() => selectedBank = bank),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSelectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const Color colorBlue = Color(0xFF0D71EE);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? colorBlue.withValues(alpha: 0.1)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorBlue
                : (isDark
                      ? Colors.white12
                      : Colors.black.withValues(alpha: 0.05)),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorBlue
                  : (isDark ? Colors.white : Colors.black54),
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.white : colorBlue)
                    : (isDark ? Colors.white70 : Colors.black54),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    bool compact = false,
    String? logoUrl,
  }) {
    const Color colorBlue = Color(0xFF0D71EE);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: compact ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorBlue.withValues(alpha: 0.1)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorBlue
                : (isDark
                      ? Colors.white12
                      : Colors.black.withValues(alpha: 0.05)),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            if (logoUrl != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: logoUrl.isEmpty
                      ? Icon(
                          Icons.account_balance,
                          color: isDark ? Colors.white24 : Colors.black12,
                          size: 20,
                        )
                      : Image.network(
                          logoUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.account_balance,
                            color: isDark ? Colors.white24 : Colors.black12,
                            size: 20,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: compact ? 14 : 16,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: colorBlue, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    if (currentStep == 0) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: isSaving ? null : () => setState(() => currentStep--),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: isDark ? Colors.white54 : Colors.black45,
            ),
            child: const Text('Précédent'),
          ),
        ),
        const SizedBox(width: 16),
        if (currentStep == 2)
          Expanded(
            child: ElevatedButton(
              onPressed: (selectedBank != null && !isSaving)
                  ? _savePatrimoine
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D71EE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Enregistrer',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
      ],
    );
  }
}
