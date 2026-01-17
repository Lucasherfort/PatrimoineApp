import 'package:supabase_flutter/supabase_flutter.dart';
import 'liquidity_account_service.dart';
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
      // Récupérer les totaux de chaque catégorie
      final liquidityService = LiquidityAccountService();
      final savingsService = SavingsAccountService();
      final investmentService = InvestmentService();
      final advantageService = AdvantageService();

      // Liquidité
      final liquidityAccounts = await liquidityService.getUserLiquidityAccounts();
      final totalLiquidity = liquidityAccounts.fold<double>(
        0.0,
            (sum, account) => sum + account.amount,
      );

      // Épargne
      final savingsAccounts = await savingsService.getUserSavingsAccounts();
      final totalSavings = savingsAccounts.fold<double>(
        0.0,
            (sum, account) => sum + account.principal + account.interest,
      );

      // Investissement
      final totalInvestment = await investmentService.getUserInvestmentsTotalValue();

      // Avantages
      final advantageAccounts = await advantageService.getUserAdvantageAccounts();
      final totalAdvantages = advantageAccounts.fold<double>(
        0.0,
            (sum, account) => sum + account.value,
      );

      return PatrimoineDistribution(
        liquidite: totalLiquidity,
        epargne: totalSavings,
        investissement: totalInvestment,
        avantages: totalAdvantages,
      );
    } catch (e) {
      rethrow;
    }
  }
}
