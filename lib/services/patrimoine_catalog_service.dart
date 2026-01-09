import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/patrimoine_catalog.dart';

class PatrimoineCatalogService {
  static PatrimoineCatalog? _cache;

  Future<PatrimoineCatalog> loadCatalog() async {
    if (_cache != null) return _cache!;

    final String jsonString =
    await rootBundle.loadString('assets/data/patrimoine_catalog.json');

    final Map<String, dynamic> jsonData = json.decode(jsonString);

    _cache = PatrimoineCatalog.fromJson(jsonData);
    return _cache!;
  }

  Future<PatrimoineCatalog> getCatalog() async {
    return _cache ?? await loadCatalog();
  }

  void clearCache() {
    _cache = null;
  }
}
