// lib/features/medical_record/presentation/bloc/dossier_state.dart

import 'package:equatable/equatable.dart';
import '../../../data/models/dossier_models.dart';

abstract class DossierState extends Equatable {
  const DossierState();
  @override List<Object?> get props => [];

  PatientSession?      get activeSession => null;
  PatientOverviewData? get overviewData  => null;

  bool get hasActiveSession {
    final s = activeSession;
    return s != null && !s.isExpired;
  }
}

// ── Aucune session ─────────────────────────────────────────────────
class DossierNoSession extends DossierState {
  const DossierNoSession();
}

// ── Chargement d'une section ───────────────────────────────────────
// Préserve overviewData et cache déjà chargés
class DossierLoadingSection extends DossierState {
  final PatientSession session;
  final DossierSection section;

  // ← Préservé pendant le chargement d'une autre section
  final PatientOverviewData?               _overviewData;
  final Map<DossierSection, List<dynamic>> cache;

  const DossierLoadingSection({
    required this.session,
    required this.section,
    PatientOverviewData?               overviewData,
    Map<DossierSection, List<dynamic>>? cache,
  })  : _overviewData = overviewData,
        cache         = cache ?? const {};

  @override PatientSession?      get activeSession => session;
  @override PatientOverviewData? get overviewData  => _overviewData;

  @override List<Object?> get props => [session.sessionId, section];
}

// ── Section chargée ────────────────────────────────────────────────
class DossierSectionLoaded extends DossierState {
  final PatientSession session;
  final DossierSection currentSection;

  /// Données List<dynamic> pour les sections non-overview.
  /// Vide ([]) quand currentSection == overview.
  final List<dynamic> sectionData;

  /// Données overview — peuplées par _loadOverview dans le BLoC.
  /// Préservées à chaque transition vers d'autres sections.
  final PatientOverviewData? _overviewData;

  /// Cache de toutes les sections List déjà chargées.
  final Map<DossierSection, List<dynamic>> cache;

  const DossierSectionLoaded({
    required this.session,
    required this.currentSection,
    required this.sectionData,
    PatientOverviewData?               overviewData,
    Map<DossierSection, List<dynamic>>? cache,
  })  : _overviewData = overviewData,
        cache         = cache ?? const {};

  @override PatientSession?      get activeSession => session;
  @override PatientOverviewData? get overviewData  => _overviewData;

  @override List<Object?> get props => [
    session.sessionId,
    currentSection,
    sectionData.length,
    _overviewData != null,
  ];

  // ── Copies ──────────────────────────────────────────────────────

  /// Pour le tick : met à jour la session (countdown) sans rien perdre.
  DossierSectionLoaded copyWithSession(PatientSession s) =>
      DossierSectionLoaded(
        session:        s,
        currentSection: currentSection,
        sectionData:    sectionData,
        overviewData:   _overviewData,
        cache:          cache,
      );

  /// Quand une section List est chargée — préserve overviewData.
  DossierSectionLoaded copyWithSection({
    required DossierSection section,
    required List<dynamic>  data,
  }) {
    final updated = Map<DossierSection, List<dynamic>>.from(cache)
      ..[section] = data;
    return DossierSectionLoaded(
      session:        session,
      currentSection: section,
      sectionData:    data,
      overviewData:   _overviewData, // ← préservé
      cache:          updated,
    );
  }

  /// Quand l'overview est chargé — met overviewData + currentSection.
  DossierSectionLoaded copyWithOverview(PatientOverviewData data) =>
      DossierSectionLoaded(
        session:        session,
        currentSection: DossierSection.overview,
        sectionData:    const [],
        overviewData:   data,
        cache:          cache, // ← préservé
      );
}

// ── Erreur sur une section ─────────────────────────────────────────
// Préserve overviewData et cache
class DossierSectionError extends DossierState {
  final PatientSession session;
  final DossierSection section;
  final String         message;

  final PatientOverviewData?               _overviewData;
  final Map<DossierSection, List<dynamic>> cache;

  const DossierSectionError({
    required this.session,
    required this.section,
    required this.message,
    PatientOverviewData?               overviewData,
    Map<DossierSection, List<dynamic>>? cache,
  })  : _overviewData = overviewData,
        cache         = cache ?? const {};

  @override PatientSession?      get activeSession => session;
  @override PatientOverviewData? get overviewData  => _overviewData;

  @override List<Object?> get props => [session.sessionId, section, message];
}

// ── Session expirée ────────────────────────────────────────────────
class DossierSessionExpiredState extends DossierState {
  const DossierSessionExpiredState();
}