import 'package:workmanager/workmanager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'patrimoine_service.dart';
import 'notification_service.dart';
import 'settings_service.dart';
import 'package:intl/intl.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // 1. Vérification si les notifications sont activées
      final settings = SettingsService();
      final isEnabled = await settings.areNotificationsEnabled();
      if (!isEnabled) return true;

      // 2. Initialisation Supabase (si pas déjà fait)
      try {
        await Supabase.initialize(
          url: 'https://hkwrmzubtmdoolleqnyt.supabase.co',
          publishableKey:
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhrd3JtenVidG1kb29sbGVxbnl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgwNTk3NTIsImV4cCI6MjA4MzYzNTc1Mn0.5h6Fcn5MmrEun3OutmI12M8_gk8LFr5WeZomK-fl9FA',
        );
      } catch (e) {
        // Déjà initialisé ou erreur mineure, on ignore
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return true;

      final service = PatrimoineService();
      final currentInvestments = await service.getInvestmentsValue();
      final historicalData = await service.getLatestHistoricalInvestment();

      if (historicalData != null) {
        final previousValue = historicalData['value'] as double;
        final diff = currentInvestments - previousValue;

        // On ne notifie que si variation significative (> 0.01€)
        if (diff.abs() > 0.01) {
          final percentage =
              previousValue > 0 ? (diff / previousValue) * 100 : 0.0;

          final formatter = NumberFormat.currency(
            locale: 'fr_FR',
            symbol: '€',
            decimalDigits: 2,
          );

          final String diffStr =
              "${diff >= 0 ? '+' : ''}${formatter.format(diff)}";
          final String percStr =
              "${percentage >= 0 ? '+' : ''}${percentage.toStringAsFixed(2)}%";
          final String emoji = diff >= 0 ? "🚀" : "📉";

          final now = DateTime.now();
          final dateStr = DateFormat('dd/MM').format(now);

          await NotificationService().showNotification(
            title: "Marchés • $dateStr $emoji",
            body:
                "Aujourd'hui, votre portefeuille affiche une variation de $diffStr ($percStr).",
          );
        }
      }

      // 4. On enregistre la valeur d'aujourd'hui pour demain
      await Supabase.instance.client.from('wealth_history').insert({
        'user_id': user.id,
        'total_investments': currentInvestments,
      });

      return true;
    } catch (e) {
      // On retourne true pour éviter le spam de retries en cas d'erreur
      return true;
    }
  });
}

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);
  }

  Future<void> registerDailyTask() async {
    // On annule d'abord toute tâche existante pour éviter les doublons
    await Workmanager().cancelByUniqueName("daily-wealth-check");

    // On programme une tâche périodique
    await Workmanager().registerPeriodicTask(
      "daily-wealth-check",
      "daily-wealth-check-task",
      frequency: const Duration(hours: 24),
      initialDelay: _calculateInitialDelay(),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  Future<void> cancelDailyTask() async {
    await Workmanager().cancelByUniqueName("daily-wealth-check");
  }

  Duration _calculateInitialDelay() {
    final now = DateTime.now();
    // On vise 18h00
    var target = DateTime(now.year, now.month, now.day, 18, 0);

    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }

    return target.difference(now);
  }
}
