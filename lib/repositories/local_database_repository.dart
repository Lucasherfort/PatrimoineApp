import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/local_database.dart';

class LocalDatabaseRepository {
  Future<LocalDatabase> load() async {
    try {
      // Essaie d'abord de charger depuis le stockage local
      final localDb = await _loadFromLocal();
      if (localDb != null) {
        print('✅ Chargé depuis le stockage local');
        return localDb;
      }
    } catch (e) {
      print('⚠️ Pas de fichier local, chargement depuis assets...');
    }

    // Si pas de fichier local, charge depuis assets
    print('📂 Chargement de assets/data/data.json...');
    final jsonString = await rootBundle.loadString('assets/data/patrimoine.json'); // ✅ Changé ici
    final jsonData = json.decode(jsonString);
    print('✅ Chargé depuis assets');
    return LocalDatabase.fromJson(jsonData);
  }

  Future<LocalDatabase?> _loadFromLocal() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/patrimoine.json'); // ✅ Changé ici aussi

    if (await file.exists()) {
      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString);
      return LocalDatabase.fromJson(jsonData);
    }

    return null;
  }

  Future<void> save(LocalDatabase db) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/patrimoine.json'); // ✅ Changé ici aussi

    final jsonData = db.toJson();
    final jsonString = JsonEncoder.withIndent('  ').convert(jsonData);

    await file.writeAsString(jsonString);
    print('✅ Base de données sauvegardée dans: ${file.path}');
  }
}