import 'package:flutter/material.dart';

import '../repositories/local_database_repository.dart';
import '../services/patrimoine_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double patrimoineTotal = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatrimoine();
  }

  Future<void> _loadPatrimoine() async {
    final repo = LocalDatabaseRepository();
    final db = await repo.load();
    final service = PatrimoineService(db);

    // Pour le moment, userId = 1
    final total = service.getTotalPatrimoineForUser(1);

    setState(() {
      patrimoineTotal = total;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patrimoine App")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Text(
              "Patrimoine total : ${patrimoineTotal.toStringAsFixed(2)} €",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
