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

  // Ta palette de couleurs officielle
  static const Color colorDarkBg = Color(0xFF060B26);
  static const Color colorBlueMain = Color(0xFF0D71EE);
  static const Color colorBlueSky = Color(0xFF67C6F2);
  static const Color colorSurface = Color(0xFF1E293B);

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
      backgroundColor: colorDarkBg,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // Léger rappel du dégradé en fond pour ne pas avoir un noir plat
          gradient: RadialGradient(
            center: const Alignment(-0.8, -0.7),
            radius: 1.2,
            colors: [colorBlueMain.withValues(alpha: 0.1), colorDarkBg],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- LOGO SECTION (ÉPURÉE) ---
                Column(
                  children: [
                    Image.asset(
                      'assets/icon/patrimoine360.png',
                      width:
                          120, // Taille augmentée puisqu'il n'y a plus de container
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(
                      height: 16,
                    ), // Espace réduit pour coller au logo
                    const Text(
                      'Patrimoine 360',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Gérez votre avenir sereinement',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.5),
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
                    child: Text(
                      "Mot de passe oublié ?",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),

                // Message d'erreur
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFF87171),
                        fontSize: 13,
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // --- BOUTON CONNEXION (DÉGRADÉ) ---
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [colorBlueSky, colorBlueMain],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorBlueMain.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- CRÉATION COMPTE ---
                TextButton(
                  onPressed: isLoading ? null : _signup,
                  child: RichText(
                    text: TextSpan(
                      text: "Pas encore de compte ? ",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      children: const [
                        TextSpan(
                          text: "S'inscrire",
                          style: TextStyle(
                            color: colorBlueSky,
                            fontWeight: FontWeight.bold,
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
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: colorBlueSky.withValues(alpha: 0.7),
          size: 22,
        ),
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        filled: true,
        fillColor: colorSurface.withValues(alpha: 0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: colorBlueMain, width: 2),
        ),
      ),
    );
  }
}
