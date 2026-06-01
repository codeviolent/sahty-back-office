import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/api/api_error.dart';
import '../../data/datasource/auth_datasource.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthDatasource _datasource;

  AuthBloc(this._datasource) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthDeviceApproved>(_onDeviceApproved);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthSessionRestored>(_onRestore);
    on<AuthSessionCheckRequested>(_onCheckSession);
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await _datasource.login(
        email: event.email,
        password: event.password,
      );

      // Vérifier que le rôle autorise l'accès au back office
      const allowedRoles = ['medecin', 'admin', 'staff', 'pharmacien'];
      if (!allowedRoles.contains(result.role)) {
        emit(const AuthError('Accès réservé au personnel médical autorisé.'));
        return;
      }

      // Stocker en session
      SessionService.setAuth(
        jwt: result.jwt,
        userId: result.userId,
        role: result.role,
        doctorName: result.doctorName,
        doctorId: result.doctorId,
      );

      log(
        '[AuthBloc] Connexion réussie: ${result.role} — ${result.doctorName}',
      );

      // → Passer au Device Trust (gate 2)
      emit(
        AuthPendingDeviceTrust(
          jwt: result.jwt,
          role: result.role,
          userId: result.userId,
          doctorName: result.doctorName,
        ),
      );
    } on ApiError catch (e) {
      log('[AuthBloc] Erreur API: ${e.message} (${e.statusCode})');
      final message = switch (e.type) {
        ApiErrorType.unauthorized => 'Identifiant ou mot de passe incorrect.',
        ApiErrorType.rateLimited =>
          'Trop de tentatives. Réessayez dans quelques minutes.',
        ApiErrorType.networkError =>
          'Impossible de joindre le serveur. Vérifiez votre réseau.',
        ApiErrorType.forbidden => 'Accès non autorisé pour ce compte.',
        _ => 'Erreur de connexion (${e.statusCode}). Réessayez.',
      };
      emit(AuthError(message));
    } catch (e) {
      log('[AuthBloc] Exception inattendue: $e');
      emit(const AuthError('Erreur inattendue. Contactez l\'administrateur.'));
    }
  }

  // ── Device Approved ───────────────────────────────────────────
  // Appelé depuis DeviceTrustScreen.onDeviceApproved → AppRoot
  void _onDeviceApproved(AuthDeviceApproved event, Emitter<AuthState> emit) {
    if (!SessionService.isAuthenticated) {
      emit(AuthLoggedOut());
      return;
    }
    log('[AuthBloc] Appareil approuvé → Shell');
    emit(
      AuthAuthenticated(
        jwt: SessionService.jwt!,
        role: SessionService.role!,
        userId: SessionService.userId!,
        doctorName: SessionService.doctorName ?? 'Médecin',
      ),
    );
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _datasource.logout();
    SessionService.clear();
    log('[AuthBloc] Déconnecté');
    emit(AuthLoggedOut());
  }

  void _onCheckSession(
    AuthSessionCheckRequested event,
    Emitter<AuthState> emit,
  ) {
    if (SessionService.isAuthenticated) {
      emit(
        AuthAuthenticated(
          jwt: SessionService.jwt!,
          role: SessionService.role!,
          userId: SessionService.userId!,
          doctorName: SessionService.doctorName ?? 'Médecin',
        ),
      );
    } else {
      emit(AuthLoggedOut());
    }
  }

  void _onRestore(AuthSessionRestored event, Emitter<AuthState> emit) {
    if (SessionService.isAuthenticated) {
      emit(
        AuthAuthenticated(
          jwt: SessionService.jwt!,
          role: SessionService.role!,
          userId: SessionService.userId!,
          doctorName: SessionService.doctorName ?? 'Utilisateur',
        ),
      );
    } else {
      emit(AuthLoggedOut());
    }
  }
}
