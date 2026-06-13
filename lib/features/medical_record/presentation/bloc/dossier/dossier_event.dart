// lib/features/medical_record/presentation/bloc/dossier_event.dart

import 'package:equatable/equatable.dart';
import '../../../data/models/dossier_models.dart';

abstract class DossierEvent extends Equatable {
  const DossierEvent();
  @override List<Object?> get props => [];
}

/// Session ouverte après validation ScannerBloc
class DossierSessionStarted extends DossierEvent {
  final PatientSession session;
  const DossierSessionStarted(this.session);
  @override List<Object> get props => [session.sessionId];
}

/// Médecin demande une section (overview ou liste)
class DossierSectionRequested extends DossierEvent {
  final DossierSection section;
  const DossierSectionRequested(this.section);
  @override List<Object> get props => [section];
}

/// Médecin ferme la session manuellement
class DossierSessionClosed extends DossierEvent {}

/// Timer 30 min expiré
class DossierSessionExpired extends DossierEvent {}

/// Tick 30s → mise à jour countdown
class DossierTickRequested extends DossierEvent {}