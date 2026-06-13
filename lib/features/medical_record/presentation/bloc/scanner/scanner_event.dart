import 'package:equatable/equatable.dart';

abstract class ScannerEvent extends Equatable {
  const ScannerEvent();
  @override List<Object?> get props => [];
}

/// QR Code détecté par la caméra
class ScannerQrDetected extends ScannerEvent {
  final String qrToken;
  const ScannerQrDetected(this.qrToken);
  @override List<Object> get props => [qrToken];
}

/// Médecin soumet le PIN à 4 chiffres
class ScannerPinSubmitted extends ScannerEvent {
  final String pin;
  const ScannerPinSubmitted(this.pin);
  @override List<Object> get props => [pin];
}

/// Remettre à zéro (rescanner)
class ScannerReset extends ScannerEvent {}