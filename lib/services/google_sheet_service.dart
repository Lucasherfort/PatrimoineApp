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

    // Lecture du Sheet
    final response = await sheetsApi.spreadsheets.values.get(
      "1c51XUhRGJctsEY_Q_p2y2yTn4AQlMPveawWnQfq3Py8",
      "ETFs!A1:H100",
    );

    final rows = response.values;

    if (rows == null || rows.isEmpty)
    {
      return [];
    }

    // La première ligne contient les en-têtes
    final headers = rows.first.map((e) => e.toString().toLowerCase()).toList();

    // Convertir les lignes suivantes en Map
    final etfs = rows.skip(1).map((row) {
      final Map<String, dynamic> etf = {};

      for (int i = 0; i < headers.length; i++) {
        etf[headers[i]] = i < row.length ? row[i] : null;
      }

      return etf;
    }).toList();

    return etfs;
  }

  Future<Map<String, dynamic>?> fetchEtfByTicker(String ticker) async {
    final etfs = await fetchEtfs();
    try {
      return etfs.firstWhere(
            (etf) => etf['ticker']?.toString().toUpperCase() == ticker.toUpperCase(),
      );
    } catch (e)
    {
      return null;
    }
  }
}