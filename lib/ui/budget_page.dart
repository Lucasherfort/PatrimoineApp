import 'package:flutter/material.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  // Tes couleurs officielles
  static const Color colorBlueMain = Color(0xFF0D71EE);
  static const Color colorDarkBg = Color(0xFF060B26);
  static const Color colorGreenLogo = Color(0xFF2DB23A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorDarkBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration icône avec dégradé subtil
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: colorBlueMain.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorBlueMain.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 80,
                color: colorBlueMain,
              ),
            ),
            const SizedBox(height: 24),
            // Titre avec ton identité visuelle
            const Text(
              "Mon Budget",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            // Texte explicatif
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "La gestion intelligente de vos revenus et dépenses arrive bientôt.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Badge "En cours de développement"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorGreenLogo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorGreenLogo.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                "SOON",
                style: TextStyle(
                  color: colorGreenLogo,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
