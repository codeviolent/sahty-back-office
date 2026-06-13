import 'package:equatable/equatable.dart';
import '../../../data/models/dossier_models.dart';

abstract class ScannerState extends Equatable {
  const ScannerState();
  @override List<Object?> get props => [];
}

/// État initial : caméra active, aucun QR détecté
class ScannerScanning extends ScannerState {}

/// QR détecté, en attente du PIN
class ScannerAwaitingPin extends ScannerState {
  final String qrToken;
  const ScannerAwaitingPin(this.qrToken);
  @override List<Object> get props => [qrToken];
}

/// Appel API en cours (vérification QR + PIN)
class ScannerVerifying extends ScannerState {}

/// Accès accordé — session ouverte
class ScannerGranted extends ScannerState {
  final PatientSession session;
  const ScannerGranted(this.session);
  @override List<Object> get props => [session];
}

/// PIN incorrect (avec compteur de tentatives restantes)
class ScannerDenied extends ScannerState {
  final String message;
  final int    attemptsLeft;
  const ScannerDenied({
    required this.message,
    this.attemptsLeft = 0,
  });
  @override List<Object> get props => [message, attemptsLeft];
}

/// 5 tentatives atteintes → bloqué 30 min
class ScannerBlocked extends ScannerState {
  final String message;
  const ScannerBlocked(this.message);
  @override List<Object> get props => [message];
}

/// QR invalide (token inconnu)
class ScannerQrInvalid extends ScannerState {
  final String message;
  const ScannerQrInvalid(this.message);
  @override List<Object> get props => [message];
}

/// Erreur réseau / serveur
class ScannerError extends ScannerState {
  final String message;
  const ScannerError(this.message);
  @override List<Object> get props => [message];
}