import 'package:flutter/material.dart';
import '../models/patrimoine_catalog.dart';
import '../models/patrimoine_category.dart';
import '../models/patrimoine_type.dart';
import '../models/local_database.dart';
import '../models/restaurant_voucher.dart';
import '../repositories/local_database_repository.dart';
import '../services/patrimoine_catalog_service.dart';
import '../services/patrimoine_service.dart';
import '../services/patrimoine_wizard_service.dart';
import '../models/bank.dart';
import 'category_step.dart';
import 'type_step.dart';

class AddPatrimoineWizard extends StatefulWidget {
  const AddPatrimoineWizard({super.key});

  @override
  State<AddPatrimoineWizard> createState() => _AddPatrimoineWizardState();
}

class _AddPatrimoineWizardState extends State<AddPatrimoineWizard> {
  final _repo = LocalDatabaseRepository();
  final _catalogService = PatrimoineCatalogService();

  late final PatrimoineWizardService wizardService;
  PatrimoineService? patrimoineService;

  PatrimoineCatalog? catalog;
  PatrimoineCategory? selectedCategory;
  PatrimoineType? selectedType;
  Bank? selectedBank;
  RestaurantVoucher? selectedVoucher;
  double? initialBalance;

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _catalogService.getCatalog(),
        _repo.load(),
      ]);

      catalog = results[0] as PatrimoineCatalog;
      final LocalDatabase db = results[1] as LocalDatabase;

      patrimoineService = PatrimoineService(db);
      wizardService = PatrimoineWizardService(_repo);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMessage != null) return Center(child: Text("Erreur: $errorMessage"));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ajouter un élément",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),

            // 1️⃣ Catégorie
            if (catalog != null)
              CategoryStep(
                catalog: catalog!,
                selectedCategory: selectedCategory,
                onChanged: (category) {
                  setState(() {
                    selectedCategory = category;
                    selectedType = null;
                    selectedBank = null;
                    selectedVoucher = null;
                  });
                },
              ),
            const SizedBox(height: 16),

            // 2️⃣ Type
            if (selectedCategory != null)
              TypeStep(
                category: selectedCategory!,
                catalog: catalog!,
                selectedType: selectedType,
                onChanged: (type) {
                  setState(() {
                    selectedType = type;
                    selectedBank = null;
                    selectedVoucher = null;
                  });
                },
              ),
            const SizedBox(height: 16),

            // 3️⃣ Dropdown Banque (si type bancaire)
            if (selectedType != null && selectedType!.entityType != 'restaurantVoucher')
              FutureBuilder<List<Bank>>(
                future: wizardService.getAvailableBanksForType(selectedType!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: CircularProgressIndicator(),
                    );
                  }
                  final banks = snapshot.data!;
                  return DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: "Banque",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedBank?.id,
                    items: banks.map((b) {
                      return DropdownMenuItem<int>(
                        value: b.id,
                        child: Text(b.name),
                      );
                    }).toList(),
                    onChanged: (id) {
                      setState(() {
                        selectedBank = banks.firstWhere((b) => b.id == id);
                        selectedVoucher = null;
                      });
                    },
                  );
                },
              ),

            // 3️⃣ Dropdown Plateforme (si titres restaurant)
            if (selectedType != null && selectedType!.entityType == 'restaurantVoucher')
              FutureBuilder<List<RestaurantVoucher>>(
                future: wizardService.getAvailableVouchers(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: CircularProgressIndicator(),
                    );
                  }
                  final vouchers = snapshot.data!;
                  return DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: "Plateforme",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedVoucher?.id,
                    items: vouchers.map((v) {
                      return DropdownMenuItem<int>(
                        value: v.id,
                        child: Text(v.name),
                      );
                    }).toList(),
                    onChanged: (id) {
                      setState(() {
                        selectedVoucher = vouchers.firstWhere((v) => v.id == id);
                        selectedBank = null;
                      });
                    },
                  );
                },
              ),
            const SizedBox(height: 16),

            // 4️⃣ Solde
            if (selectedType != null)
              TextFormField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Solde initial (€)",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  initialBalance = double.tryParse(value.replaceAll(',', '.'));
                },
              ),
            const SizedBox(height: 24),

            // 5️⃣ Bouton créer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit() ? _submit : null,
                child: const Text("Créer"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canSubmit() {
    if (selectedType == null || initialBalance == null) return false;
    if (selectedType!.entityType == 'restaurantVoucher') return selectedVoucher != null;
    return selectedBank != null;
  }

  Future<void> _submit() async {
    if (selectedType == null || initialBalance == null) return;

    final success = await wizardService.createPatrimoine(
      type: selectedType!,
      bank: selectedBank,
      voucher: selectedVoucher,
      balance: initialBalance!,
      userId: 1,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '${selectedType!.name} créé avec succès'
            : 'Erreur lors de la création'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) Navigator.pop(context, true);
  }
}
