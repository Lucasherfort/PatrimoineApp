import 'package:flutter/material.dart';
import 'package:patrimoine/widgets/type_step.dart';
import '../models/patrimoine_catalog.dart';
import '../models/patrimoine_category.dart';
import '../models/patrimoine_type.dart';
import '../models/local_database.dart';
import '../repositories/local_database_repository.dart';
import '../services/patrimoine_catalog_service.dart';
import '../services/patrimoine_wizard_service.dart';
import '../models/bank.dart';
import 'category_step.dart';


class AddPatrimoineWizard extends StatefulWidget {
  const AddPatrimoineWizard({super.key});

  @override
  State<AddPatrimoineWizard> createState() => _AddPatrimoineWizardState();
}

class _AddPatrimoineWizardState extends State<AddPatrimoineWizard> {
  final _catalogService = PatrimoineCatalogService();
  final _repo = LocalDatabaseRepository();

  late final PatrimoineWizardService wizardService =
  PatrimoineWizardService(_repo);

  PatrimoineCategory? selectedCategory;
  PatrimoineType? selectedType;

  Bank? selectedBank;
  RestaurantVoucher? selectedVoucher;

  double? initialBalance;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Object>>(
      future: Future.wait([
        _catalogService.getCatalog(),
        _repo.load(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          );
        }

        final PatrimoineCatalog catalog =
        snapshot.data![0] as PatrimoineCatalog;
        final LocalDatabase db = snapshot.data![1] as LocalDatabase;

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
                Text(
                  "Ajouter un élément",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),

                // 1️⃣ CATÉGORIE
                CategoryStep(
                  catalog: catalog,
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

                // 2️⃣ TYPE
                if (selectedCategory != null)
                  TypeStep(
                    category: selectedCategory!,
                    catalog: catalog,
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

                // 3️⃣ BANQUE / PLATEFORME
                if (selectedType != null)
                  DropdownButtonFormField<Object>(
                    decoration: InputDecoration(
                      labelText: selectedType!.entityType ==
                          'restaurantVoucher'
                          ? "Plateforme"
                          : "Banque",
                      border: const OutlineInputBorder(),
                    ),
                    value: selectedType!.entityType == 'restaurantVoucher'
                        ? selectedVoucher
                        : selectedBank,
                    items: _buildBankItems(
                      selectedType!,
                      db.banks,
                      db.restaurantVouchers,
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value is Bank) {
                          selectedBank = value;
                          selectedVoucher = null;
                        } else if (value is RestaurantVoucher) {
                          selectedVoucher = value;
                          selectedBank = null;
                        }
                      });
                    },
                  ),

                const SizedBox(height: 16),

                // 4️⃣ SOLDE
                if (selectedType != null)
                  TextFormField(
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Solde initial (€)",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      initialBalance =
                          double.tryParse(value.replaceAll(',', '.'));
                    },
                  ),

                const SizedBox(height: 24),

                // 5️⃣ CRÉER
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
      },
    );
  }

  // 🔁 Items banque / plateforme
  List<DropdownMenuItem<Object>> _buildBankItems(
      PatrimoineType type,
      List<Bank> banks,
      List<RestaurantVoucher> vouchers,
      ) {
    if (type.entityType == 'restaurantVoucher') {
      return vouchers
          .map(
            (v) => DropdownMenuItem<Object>(
          value: v,
          child: Text(v.name),
        ),
      )
          .toList();
    }

    return banks
        .map(
          (b) => DropdownMenuItem<Object>(
        value: b,
        child: Text(b.name),
      ),
    )
        .toList();
  }

  bool _canSubmit() {
    if (selectedType == null || initialBalance == null) return false;

    if (selectedType!.entityType == 'restaurantVoucher') {
      return selectedVoucher != null;
    }

    return selectedBank != null;
  }

  Future<void> _submit() async {
    final success = await wizardService.createPatrimoine(
      type: selectedType!,
      bank: selectedBank,
      voucher: selectedVoucher,
      balance: initialBalance!,
      userId: 1,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selectedType!.name} créé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la création'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
