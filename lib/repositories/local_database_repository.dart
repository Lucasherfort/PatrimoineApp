import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/local_database.dart';

class LocalDatabaseRepository {
  /// Charge la base locale depuis le JSON
  Future<LocalDatabase> load() async {
    try {
      final jsonString = await rootBundle.loadString("assets/data/patrimoine.json");
      final jsonMap = json.decode(jsonString);
      return LocalDatabase.fromJson(jsonMap);
    } catch (_) {
      // Si le fichier n'existe pas ou erreur, retourne une base vide
      return LocalDatabase.empty();
    }
  }
}