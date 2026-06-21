import 'package:supabase_flutter/supabase_flutter.dart';
import 'liquidity_service.dart';
import 'savings_account_service.dart';
import 'investment_service.dart';
import 'advantage_service.dart';

class PatrimoineDistribution {
  final double liquidite;
  final double epargne;
  final double investissement;
  final double avantages;

  PatrimoineDistribution({
    required this.liquidite,
    required this.epargne,
    required this.investissement,
    required this.avantages,
  });

  double get total => liquidite + epargne + investissement + avantages;
}

class GraphService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<PatrimoineDistribution> getPatrimoineDistribution() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return PatrimoineDistribution(
        liquidite: 0,
        epargne: 0,
        investissement: 0,
        avantages: 0,
      );
    }

    try {
      // Utilisation des méthodes centralisées des services
      final results = await Future.wait([
        LiquidityService().getTotalLiquidityValue(),
        SavingsAccountService().getTotalSavingsValue(),
        InvestmentService().getTotalPortfolioValue(),
        AdvantageService().getTotalAdvantageValue(),
      ]);

      return PatrimoineDistribution(
        liquidite: results[0],
        epargne: results[1],
        investissement: results[2],
        avantages: results[3],
      );
    } catch (e) {
      rethrow;
    }
  }
}
