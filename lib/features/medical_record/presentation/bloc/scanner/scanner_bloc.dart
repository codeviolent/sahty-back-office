import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasource/dossier_datasource.dart';
import 'scanner_event.dart';
import 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final DossierDatasource _datasource;
  String? _pendingQrToken;

  ScannerBloc(this._datasource) : super(ScannerScanning()) {
    on<ScannerQrDetected>  (_onQrDetected);
    on<ScannerPinSubmitted>(_onPinSubmitted);
    on<ScannerReset>       (_onReset);
  }

  // ── QR détecté ────────────────────────────────────────────────
  void _onQrDetected(
    ScannerQrDetected event,
    Emitter<ScannerState> emit,
  ) {
    // Éviter de déclencher si déjà en attente de PIN
    if (state is ScannerAwaitingPin || state is ScannerVerifying) return;

    log('[ScannerBloc] QR détecté: ${event.qrToken.substring(0, 8)}...');
    _pendingQrToken = event.qrToken;
    emit(ScannerAwaitingPin(event.qrToken));
  }

  // ── PIN soumis ────────────────────────────────────────────────
  Future<void> _onPinSubmitted(
    ScannerPinSubmitted event,
    Emitter<ScannerState> emit,
  ) async {
    if (_pendingQrToken == null) {
      emit(const ScannerError('QR Code requis avant le PIN'));
      return;
    }
    if (event.pin.length != 4) {
      emit(const ScannerDenied(message: 'PIN doit contenir 4 chiffres'));
      return;
    }

    emit(ScannerVerifying());
    log('[ScannerBloc] Vérification PIN...');

    try {
      final session = await _datasource.verifyAccess(
        qrToken: _pendingQrToken!,
        pin:     event.pin,
      );

      log('[ScannerBloc] Accès accordé: ${session.displayName}');
      emit(ScannerGranted(session));

    } catch (e) {
      log('[ScannerBloc] Erreur: $e');
      final msg = e.toString().toLowerCase();

      if (_isRateLimit(msg)) {
        emit(const ScannerBlocked(
          'Accès bloqué — trop de tentatives. Réessayez dans 30 minutes.'));
        return;
      }

      if (_isNotFound(msg)) {
        _pendingQrToken = null;
        emit(const ScannerQrInvalid('QR Code invalide ou expiré.'));
        return;
      }

      // PIN incorrect — extraire le nombre de tentatives restantes
      final attemptsLeft = _extractAttempts(msg);
      emit(ScannerDenied(
        message:      'PIN incorrect.',
        attemptsLeft: attemptsLeft,
      ));
    }
  }

  // ── Reset ─────────────────────────────────────────────────────
  void _onReset(ScannerReset event, Emitter<ScannerState> emit) {
    log('[ScannerBloc] Reset');
    _pendingQrToken = null;
    emit(ScannerScanning());
  }

  // ── Helpers ───────────────────────────────────────────────────
  bool _isRateLimit(String msg) =>
      msg.contains('429') ||
      msg.contains('bloqué') ||
      msg.contains('trop de tentatives');

  bool _isNotFound(String msg) =>
      msg.contains('404') ||
      msg.contains('invalide') ||
      msg.contains('introuvable');

  int _extractAttempts(String msg) {
    final match = RegExp(r'(\d+)\s+tentative').firstMatch(msg);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }
}