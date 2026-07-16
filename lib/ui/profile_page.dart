import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:patrimoine360/services/settings_service.dart';
import 'package:patrimoine360/services/theme_manager.dart';
import 'package:patrimoine360/services/financial_profile_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final String appVersion;
  const ProfilePage({super.key, required this.appVersion});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _salaryController;
  late TextEditingController _investmentController;

  @override
  void initState() {
    super.initState();
    final manager = FinancialProfileManager();
    _salaryController = TextEditingController(
      text: manager.monthlyNetSalary > 0
          ? manager.monthlyNetSalary.toString()
          : '',
    );
    _investmentController = TextEditingController(
      text: manager.monthlyInvestment > 0
          ? manager.monthlyInvestment.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _investmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color colorRed = Color(0xFFFC5555);
    const Color colorBlue = Color(0xFF0D71EE);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // --- ENTÊTE MENU ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: isDark
                    ? null
                    : Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colorBlue.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, size: 32, color: colorBlue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "MON COMPTE",
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          Supabase.instance.client.auth.currentUser?.email ??
                              "Utilisateur",
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- SECTION APPARENCE ---
            _buildAppearanceSection(context),

            const SizedBox(height: 24),

            // --- SECTION PROFIL FINANCIER ---
            _buildFinancialProfileSection(context),

            const SizedBox(height: 24),

            // --- AUTRES OPTIONS ---
            _buildMenuOption(
              context,
              icon: Icons.info_outline,
              title: "À propos",
              subtitle: "Version de l'application",
              trailing: Text(
                widget.appVersion,
                style: TextStyle(
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- BOUTON DÉCONNEXION ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorRed.withValues(alpha: 0.1),
                  foregroundColor: colorRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: colorRed.withValues(alpha: 0.3)),
                  elevation: 0,
                ),
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text(
                  "DÉCONNEXION",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? null
            : Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 12,
          ),
        ),
        trailing:
            trailing ??
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "APPARENCE",
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: isDark
                ? null
                : Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: ListenableBuilder(
            listenable: ThemeManager(),
            builder: (context, child) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 20,
                  ),
                ),
                title: Text(
                  "Thème de l'application",
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                trailing: DropdownButton<AppThemeMode>(
                  value: ThemeManager().appThemeMode,
                  dropdownColor: theme.cardColor,
                  underline: const SizedBox(),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (AppThemeMode? newMode) {
                    if (newMode != null) {
                      ThemeManager().setThemeMode(newMode);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: AppThemeMode.light,
                      child: Text("Clair"),
                    ),
                    DropdownMenuItem(
                      value: AppThemeMode.dark,
                      child: Text("Sombre"),
                    ),
                    DropdownMenuItem(
                      value: AppThemeMode.adaptive,
                      child: Text("Adaptatif"),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialProfileSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final manager = FinancialProfileManager();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PROFIL FINANCIER",
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: isDark
                ? null
                : Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              _buildNumericField(
                context,
                label: "Salaire net mensuel",
                controller: _salaryController,
                onChanged: (val) {
                  final d = double.tryParse(val) ?? 0.0;
                  manager.setMonthlyNetSalary(d);
                },
              ),
              const SizedBox(height: 20),
              _buildNumericField(
                context,
                label: "Investissement mensuel",
                controller: _investmentController,
                onChanged: (val) {
                  final d = double.tryParse(val) ?? 0.0;
                  manager.setMonthlyInvestment(d);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumericField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
          ],
          onChanged: onChanged,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          decoration: InputDecoration(
            isDense: true,
            suffixText: "€",
            suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0D71EE)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}
