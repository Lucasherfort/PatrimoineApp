import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  // Palette de couleurs pour le thème clair
  static const Color colorBg = Color(0xFFF8FAFC);
  static const Color colorTextPrimary = Color(0xFF0F172A);
  static const Color colorTextSecondary = Color(0xFF64748B);
  static const Color colorBlueMain = Color(0xFF0D71EE);
  static const Color colorBlueSky = Color(0xFF67C6F2);
  static const Color colorSurface = Colors.white;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty && password.isEmpty) {
      setState(() => errorMessage = "Veuillez saisir vos informations");
      return;
    }
    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = "Veuillez renseigner tous les champs");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _authService.signIn(email: email, password: password);
    } on AuthException catch (e) {
      if (mounted) {
        if (e.message.contains('Invalid login credentials')) {
          setState(
            () => errorMessage = "Identifiant ou mot de passe incorrect",
          );
        } else {
          setState(() => errorMessage = e.message);
        }
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('socketexception') ||
            errorStr.contains('connection failed') ||
            errorStr.contains('network_error')) {
          setState(
            () => errorMessage =
                "Une erreur de connexion est survenue. Vérifiez votre connexion internet puis réessayez.",
          );
        } else {
          setState(
            () => errorMessage = e.toString().replaceFirst('Exception: ', ''),
          );
        }
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(
        () => errorMessage =
            "Veuillez saisir votre email pour réinitialiser le mot de passe",
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _authService.resetPassword(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de réinitialisation envoyé'),
            backgroundColor: colorBlueMain,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => errorMessage = "Erreur lors de l'envoi de l'email");
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _signup() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Compte créé, vérifie tes emails'),
          backgroundColor: colorBlueMain,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(
          () => errorMessage = e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBg,
      body: Stack(
        children: [
          // --- EFFET DE FOND (Halos) ---
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorBlueMain.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorBlueMain.withValues(alpha: 0.05),
              ),
            ),
          ),

          // --- CONTENU PRINCIPAL ---
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- LOGO SECTION ---
                  Column(
                    children: [
                      Hero(
                        tag: 'app_logo',
                        child: Image.asset(
                          'assets/icon/patrimoine360.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Patrimoine 360',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: colorTextPrimary,
                          letterSpacing: -1.0,
                        ),
                      ),
                      Text(
                        'Gérez votre avenir sereinement',
                        style: TextStyle(
                          fontSize: 15,
                          color: colorTextSecondary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // --- INPUTS ---
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),

                  // --- MOT DE PASSE OUBLIÉ ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading ? null : _forgotPassword,
                      child: const Text(
                        "Mot de passe oublié ?",
                        style: TextStyle(
                          color: colorBlueMain,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Message d'erreur
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // --- BOUTON CONNEXION ---
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [colorBlueSky, colorBlueMain],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: colorBlueMain.withValues(alpha: 0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Se connecter',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- CRÉATION COMPTE ---
                  TextButton(
                    onPressed: isLoading ? null : _signup,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: "Pas encore de compte ? ",
                        style: const TextStyle(
                          color: colorTextSecondary,
                          fontSize: 14,
                        ),
                        children: const [
                          TextSpan(
                            text: "S'inscrire",
                            style: TextStyle(
                              color: colorBlueMain,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Helper pour les champs de saisie uniformes
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: colorTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: colorBlueMain.withValues(alpha: 0.6),
            size: 22,
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: colorTextSecondary.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          floatingLabelStyle: const TextStyle(
            color: colorBlueMain,
            fontWeight: FontWeight.bold,
          ),
          filled: true,
          fillColor: colorSurface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: colorBlueMain, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
