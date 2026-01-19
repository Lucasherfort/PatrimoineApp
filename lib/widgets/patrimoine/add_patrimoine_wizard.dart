import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../bdd/database_tables.dart';
import '../../models/advantage/provider.dart';
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
  Bank? selectedBank;

// Étape 3 : Fournisseurs
  List<Provider> providers = [];
  Provider? selectedProvider;

// Type de sélection du step 3
  Step3SelectionType? step3SelectionType;


  @override
  void initState() {
    super.initState();
    _loadCategories();
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
      final loadedSources = await _wizardService.getSourcesForCategory(category);

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

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _onCategorySelected(PatrimoineCategory? category)
  {
    setState(() {
      selectedCategory = category;
      selectedSource = null;
      selectedBank = null;
      sources = [];
      banks = [];
      providers = [];
    });

    if (category != null) {
      _loadSourcesForCategory(category);
    }
  }

  Future<void> _onSourceSelected(SourceItem? source) async {
    if (source == null) return;

    setState(() {
      selectedSource = source;
      isLoading = true;
      banks = [];
      providers = [];
      selectedBank = null;
      selectedProvider = null;
      step3SelectionType = null;
    });

    try {
      List<Bank> loadedBanks = await _loadBanksBySourceType(source);
      List<Provider> loadedProviders = await _loadProvidersBySourceType(source);

      setState(() {
        if (source.type == 'advantage') {
          providers = loadedProviders;
          step3SelectionType = Step3SelectionType.provider;
        } else {
          banks = loadedBanks;
          step3SelectionType = Step3SelectionType.bank;
        }

        currentStep = 2;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Erreur chargement étape 3: $e');
    }
  }


  void _onBankSelected(Bank? bank) {
    setState(() {
      selectedBank = bank;
    });
  }

  void _nextStep() {
    if (currentStep < 2) {
      setState(() => currentStep++);
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    }
  }

  bool _canProceedFromStep(int step) {
    switch (step) {
      case 0:
        return selectedCategory != null;
      case 1:
        return selectedSource != null;
      case 2:
        if (step3SelectionType == Step3SelectionType.bank) {
          return selectedBank != null;
        }
        if (step3SelectionType == Step3SelectionType.provider) {
          return selectedProvider != null;
        }
        return false;
      default:
        return false;
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
      if (selectedSource!.type == 'liquidity')
      {
        // Charge si le compte existe
        final existing = await Supabase.instance.client
        .from(DatabaseTables.liquiditySource)
        .select('id')
            .eq('bank_id', selectedBank!.id)
            .eq('category_id', selectedCategory!.id)
            .eq('liquidity_category_id', selectedSource!.id)
            .maybeSingle();

        int liquiditySourceId;
        if(existing != null)
          {
            liquiditySourceId = existing['id'] as int;

            // 3️⃣ Crée le user_savings_account
            await Supabase.instance.client
                .from(DatabaseTables.userLiquidityAccounts)
                .insert({
              'user_id': user.id,
              'liquidity_source_id': liquiditySourceId,
              'amount': 0
            });
          }
      }
      else if (selectedSource!.type == 'savings')
      {
        // 1️⃣ Cherche si savings_source existe
        final existing = await Supabase.instance.client
            .from(DatabaseTables.savingsSource)
            .select('id')
            .eq('bank_id', selectedBank!.id)
            .eq('category_id', selectedCategory!.id)
            .eq('savings_category_id', selectedSource!.id)
            .maybeSingle();

        int savingsSourceId;
        if (existing != null)
        {
          savingsSourceId = existing['id'] as int;

          // 3️⃣ Crée le user_savings_account
          await Supabase.instance.client
              .from('user_savings_account')
              .insert({
            'user_id': user.id,
            'savings_source_id': savingsSourceId,
            'principal': 0,
            'interest': 0,
          });
        }
      }
      else if (selectedSource!.type == 'investment')
      {
        // 1️⃣ Cherche si savings_source existe
        final existing = await Supabase.instance.client
            .from(DatabaseTables.investmentSource)
            .select('id')
            .eq('bank_id', selectedBank!.id)
            .eq('category_id', selectedCategory!.id)
            .eq('investment_category_id', selectedSource!.id)
            .maybeSingle();

        int savingsSourceId;
        if (existing != null)
        {
          savingsSourceId = existing['id'] as int;

          // 3️⃣ Crée le user_savings_account
          await Supabase.instance.client
              .from(DatabaseTables.userInvestmentAccount)
              .insert({
            'user_id': user.id,
            'investment_source_id': savingsSourceId,
            'total_contribution': 0,
            'cash_balance': 0,
            'amount': 0
          });
        }
      }
      else if (selectedSource!.type == 'advantage') {
        await Supabase.instance.client
            .from(DatabaseTables.userAdvantageAccount)
            .insert({
          'user_id': user.id,
          'advantage_source_id': selectedSource!.id,
          'value': 0,
        });
      }


      _showSuccess('Compte créé avec succès');
      if (mounted) Navigator.pop(context, true);

    } catch (e)
    {
      _showError('Erreur lors de la création: $e');
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildProgressIndicator(),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: _buildStepContent(),
            ),
          ),
          const SizedBox(height: 20),
          _buildNavigationButtons(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Ajouter un patrimoine',
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
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= currentStep;
        final isCompleted = index < currentStep;

        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green
                  : (isActive ? Colors.blue : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    switch (currentStep) {
      case 0:
        return _buildCategoryStep();
      case 1:
        return _buildSourceStep();
      case 2:
        return _buildStep3(); // ✅ ICI
      default:
        return const SizedBox();
    }
  }

  Widget _buildCategoryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Étape 1 : Catégorie',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sélectionnez le type de patrimoine que vous souhaitez ajouter',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        if (categories.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Aucune catégorie disponible',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          DropdownButtonFormField<PatrimoineCategory>(
            initialValue: selectedCategory,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              labelText: 'Catégorie',
              hintText: 'Sélectionnez une catégorie',
              prefixIcon: const Icon(Icons.category),
            ),
            items: categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(
                  category.label.isNotEmpty ? category.label : category.name,
                ),
              );
            }).toList(),
            onChanged: _onCategorySelected,
          ),
      ],
    );
  }

  Widget _buildSourceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Étape 2 : Type de compte',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          selectedCategory?.label ?? 'Type de compte',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        if (sources.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Aucune source disponible pour cette catégorie',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          DropdownButtonFormField<SourceItem>(
            initialValue: selectedSource,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              labelText: 'Type',
              hintText: 'Sélectionnez un type',
              prefixIcon: const Icon(Icons.account_balance_wallet),
            ),
            items: sources.map((source) {
              return DropdownMenuItem(
                value: source,
                child: Text(source.label),
              );
            }).toList(),
            onChanged: _onSourceSelected,
          ),
      ],
    );
  }

  Widget _buildBankStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Étape 3 : Banque',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sélectionnez la banque de votre compte',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        if (banks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Aucune banque disponible',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          DropdownButtonFormField<Bank>(
            initialValue: selectedBank,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              labelText: 'Banque',
              hintText: 'Sélectionnez une banque',
              prefixIcon: const Icon(Icons.account_balance),
            ),
            items: banks.map((bank) {
              return DropdownMenuItem(
                value: bank,
                child: Text(bank.name),
              );
            }).toList(),
            onChanged: _onBankSelected,
          ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    final canProceed = _canProceedFromStep(currentStep);

    return Row(
      children: [
        if (currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: isSaving ? null : _previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Précédent'),
            ),
          ),
        if (currentStep > 0) const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: (canProceed && !isSaving)
                ? (currentStep < 2 ? _nextStep : _savePatrimoine)
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isSaving
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Text(currentStep < 2 ? 'Suivant' : 'Enregistrer'),
          ),
        ),
      ],
    );
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

  Widget _buildStep3() {
    if (step3SelectionType == Step3SelectionType.bank) {
      return _buildBankStep();
    }

    if (step3SelectionType == Step3SelectionType.provider) {
      return _buildProviderStep();
    }

    return const SizedBox();
  }

  Widget _buildProviderStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Étape 3 : Fournisseur', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 8),
        const Text('Sélectionnez le fournisseur de votre avantage', style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 20),
        if (providers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text('Aucun fournisseur disponible', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          DropdownButtonFormField<Provider>(
            initialValue: selectedProvider,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              labelText: 'Fournisseur',
              hintText: 'Sélectionnez un fournisseur',
              prefixIcon: const Icon(Icons.store),
            ),
            items: providers.map((provider) {
              return DropdownMenuItem(value: provider, child: Text(provider.name));
            }).toList(),
            onChanged: (p) => setState(() => selectedProvider = p),
          ),
      ],
    );
  }

  Future<List<Provider>> _loadProvidersBySourceType(SourceItem source) {
    switch (source.type) {
      case 'advantage':
        return _wizardService.getProvidersForAdvantageSource(
          categoryId: selectedCategory!.id,
          advantageCategoryId: source.id,
        );

      default:
        return Future.value([]);
    }
  }

}

// Extension helper pour firstWhereOrNull
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
enum Step3SelectionType {
  bank,
  provider,
}
