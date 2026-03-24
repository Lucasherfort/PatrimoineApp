import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 🔐 Connexion
  Future<void> signIn({required String email, required String password}) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Connexion échouée');
    }
  }

  /// 🆕 Inscription
  Future<void> signUp({required String email, required String password}) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Inscription échouée');
    }
  }

  /// 🚪 Déconnexion
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// 👤 Utilisateur connecté
  User? get currentUser => _supabase.auth.currentUser;

  /// 🔄 Écoute des changements d’auth
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
