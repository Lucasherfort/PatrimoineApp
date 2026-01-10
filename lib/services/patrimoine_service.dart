import 'package:supabase_flutter/supabase_flutter.dart';

class PatrimoineService {
  final SupabaseClient supabase;

  PatrimoineService(this.supabase);

  /// Récupère le total cash du user connecté
  Future<double> getPatrimoine() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    try {
      final response = await supabase.rpc('get_total_patrimoine',
        params: {'p_user_id': user.id},
      );

      return (response as num).toDouble();
    } catch (e) {
      print('Erreur getTotalCash: $e');
      rethrow;
    }
  }
}