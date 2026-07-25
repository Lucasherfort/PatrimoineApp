import 'package:flutter/material.dart';
import 'tools/real_estate_simulator_page.dart';

class SimulatorsPage extends StatelessWidget {
  const SimulatorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                "SIMULATEURS",
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black45,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Outils de calcul",
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),
              _buildSimulatorCard(
                context,
                title: "Simulateur Immobilier",
                subtitle: "Calculez votre capacité d'achat et mensualités",
                icon: Icons.home_work,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RealEstateSimulatorPage(),
                    ),
                  );
                },
              ),
              _buildSimulatorCard(
                context,
                title: "Retraite & FIRE",
                subtitle: "Quand pourrez-vous arrêter de travailler ?",
                icon: Icons.wb_sunny_rounded,
                isPlaceholder: true,
              ),
              _buildSimulatorCard(
                context,
                title: "Capacité d'investissement",
                subtitle: "Combien pouvez-vous investir chaque mois ?",
                icon: Icons.savings,
                isPlaceholder: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimulatorCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    bool isPlaceholder = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? null
            : Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isPlaceholder
                ? (isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.03))
                : const Color(0xFF0D71EE).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: isPlaceholder
                ? (isDark ? Colors.white24 : Colors.black26)
                : const Color(0xFF0D71EE),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isPlaceholder
                ? (isDark ? Colors.white38 : Colors.black38)
                : null,
          ),
        ),
        subtitle: Text(
          isPlaceholder ? "Bientôt disponible" : subtitle,
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 12,
          ),
        ),
        trailing: isPlaceholder
            ? null
            : Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
      ),
    );
  }
}
