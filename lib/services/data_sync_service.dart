import 'package:flutter/material.dart';

class DataSyncService extends ChangeNotifier {
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  /// Appelé pour notifier tous les écrans que les données globales ont changé
  void notifyDataUpdated() {
    notifyListeners();
  }
}
