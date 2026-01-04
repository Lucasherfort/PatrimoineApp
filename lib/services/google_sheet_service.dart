import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';

class GoogleSheetsService {
  static const _scopes = [SheetsApi.spreadsheetsReadonlyScope];

  Future<List<Map<String, dynamic>>> fetchEtfs() async {
    // Charger le JSON
    final jsonString = await rootBundle.loadString(
      'assets/google/service_account.json',
    );
    final credentials = ServiceAccountCredentials.fromJson(
      json.decode(jsonString),
    );

    // Auth
    final client = await clientViaServiceAccount(credentials, _scopes);
    final sheetsApi = SheetsApi(client);

    print('📊 Récupération des données Google Sheets...');

    // Lecture du Sheet
    final response = await sheetsApi.spreadsheets.values.get(
      "1c51XUhRGJctsEY_Q_p2y2yTn4AQlMPveawWnQfq3Py8",
      "ETFs!A1:H100",
    );

    final rows = response.values;

    print('📊 Nombre de lignes reçues: ${rows?.length ?? 0}');

    if (rows == null || rows.isEmpty) {
      print('⚠️ Aucune donnée reçue du Google Sheet');
      return [];
    }

    // La première ligne contient les en-têtes
    final headers = rows.first.map((e) => e.toString().toLowerCase()).toList();
    print('📋 En-têtes détectés: $headers');

    // Convertir les lignes suivantes en Map
    final etfs = rows.skip(1).map((row) {
      final Map<String, dynamic> etf = {};

      for (int i = 0; i < headers.length; i++) {
        etf[headers[i]] = i < row.length ? row[i] : null;
      }

      return etf;
    }).toList();

    print('📊 Nombre d\'ETFs récupérés: ${etfs.length}');

    // Affiche les 3 premiers ETFs pour debug
    for (int i = 0; i < etfs.length && i < 3; i++) {
      print('ETF $i: ${etfs[i]}');
    }

    return etfs;
  }

  Future<Map<String, dynamic>?> fetchEtfByTicker(String ticker) async {
    final etfs = await fetchEtfs();
    try {
      return etfs.firstWhere(
            (etf) => etf['ticker']?.toString().toUpperCase() == ticker.toUpperCase(),
      );
    } catch (e) {
      print('⚠️ ETF non trouvé pour ticker: $ticker');
      return null;
    }
  }
}