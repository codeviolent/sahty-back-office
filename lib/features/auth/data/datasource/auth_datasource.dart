import 'dart:developer';

import 'package:sahty_back_office/features/auth/data/models/auth_result.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/auth_user_model.dart';

class AuthDatasource {
  const AuthDatasource();

  // ── Connexion email + mot de passe ────────────────────────────
  Future<AuthResult>
  login({
    required String email,
    required String password,
  }) async {
    log('[AuthDatasource] Connexion: $email');
    // 1. Authentifier avec Supabase Auth
    final authData = await ApiClient.postAuth(ApiEndpoints.login, {
      'email':    email.trim(),
      'password': password.trim(),
    });

    final jwt    = authData['access_token']  as String;
    final refreshToken = authData['refresh_token'] as String?;
    final userId = (authData['user'] as Map)['id'] as String;
    // 2. Stocker temporairement le JWT pour l'appel suivant
    // On utilise ApiClient directement avec le JWT en paramètre
    final roleData = await ApiClient.getWithJwt(
      ApiEndpoints.getUserRole,
      jwt: jwt,
    );
    log('[AuthDatasource] JWT obtenu pour userId: $userId');
    final role       = roleData['role']       as String? ?? 'medecin';
    final doctorName = roleData['doctorName'] as String? ?? email.split('@').first;
    final doctorId   = roleData['doctorId']   as int?;
    log('[AuthDatasource] Rôle: $role | Médecin: $doctorName');
    // 3. Récupérer le rôle depuis user_roles
    // On appelle get-home-data (admin) ou admin-get-stats pour vérifier
    // Pour l'instant on parse le rôle depuis les metadata si disponible
    // La vraie récupération du rôle se fait via un endpoint dédié

    return AuthResult(
      jwt:          jwt,
      userId:       userId,
      role:         role,
      doctorName:   doctorName,
      doctorId:     doctorId,
      refreshToken: refreshToken,
    );
  }

  // ── Récupérer rôle + infos après connexion ────────────────────
  Future<AuthUserModel> getUserInfo(String userId) async {
    // Appel admin-get-stats pour tester si admin,
    // ou doctor-get-agenda pour médecin
    // Le rôle est dans user_roles — récupéré via une fonction dédiée

    // Pour l'instant : retourner les infos basiques
    // L'implémentation complète nécessite get-user-role Edge Function
    throw UnimplementedError('Implémenter get-user-role');
  }

  // ── Déconnexion ───────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await ApiClient.post(
        ApiEndpoints.logout,
        {},
        requireAuth: true,
      );
      log('[AuthDatasource] Déconnecté');
    } catch (e) {
      log('[AuthDatasource] Erreur logout (ignorée): $e');
      // Ignorer les erreurs de logout — toujours vider la session locale
    }
  }
}