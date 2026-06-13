import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasource/dossier_datasource.dart';
import '../../../data/models/dossier_models.dart';
import 'dossier_event.dart';
import 'dossier_state.dart';

class DossierBloc extends Bloc<DossierEvent, DossierState> {
  final DossierDatasource _datasource;
  Timer? _expiryTimer;
  Timer? _tickTimer;
  bool _overviewInFlight = false; // Protège contre double-appel overview

  DossierBloc(this._datasource) : super(const DossierNoSession()) {
    on<DossierSessionStarted>  (_onSessionStarted);
    on<DossierSectionRequested>(_onSectionRequested);
    on<DossierSessionClosed>   (_onSessionClosed);
    on<DossierSessionExpired>  (_onSessionExpired);
    on<DossierTickRequested>   (_onTick);
  }

  // ════════════════════════════════════════════════════════════════
  // Session démarrée → charge l'overview IMMÉDIATEMENT
  // UN SEUL APPEL HTTP pour toute la session
  // ════════════════════════════════════════════════════════════════
  Future<void> _onSessionStarted(
    DossierSessionStarted event,
    Emitter<DossierState>  emit,
  ) async {
    if (state.hasActiveSession) {
      log('[DossierBloc] Session déjà active — ignorée');
      return;
    }

    final session = event.session;
    log('[DossierBloc] ✅ Session: ${session.displayName} '
        '— expire dans ${session.remaining.inMinutes}min');

    _cancelTimers();
    _overviewInFlight = false;

    _expiryTimer = Timer(session.remaining, () {
      add(DossierSessionExpired());
    });
    _tickTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      add(DossierTickRequested());
    });

    // Charger l'overview directement (1 seul appel pour TOUT le dossier)
    await _loadOverview(
      session:        session,
      cache:          const {},
      cachedOverview: null,
      emit:           emit,
    );
  }

  // ════════════════════════════════════════════════════════════════
  // Section demandée — uniquement pour RETRY (via bouton Réessayer)
  // SectionDispatcher ne dispatch JAMAIS d'appels
  // ════════════════════════════════════════════════════════════════
  Future<void> _onSectionRequested(
    DossierSectionRequested event,
    Emitter<DossierState>   emit,
  ) async {
    final current = state;
    if (!current.hasActiveSession) return;

    final session = current.activeSession!;
    if (session.isExpired) {
      _cancelTimers();
      emit(const DossierSessionExpiredState());
      return;
    }

    final cache          = _extractCache(current);
    final cachedOverview = current.overviewData;

    // ── Retry overview ────────────────────────────────────────────
    if (event.section == DossierSection.overview) {
      if (_overviewInFlight) {
        log('[DossierBloc] Overview déjà en cours — ignoré');
        return;
      }
      // Si overview déjà chargé → rien à faire
      if (cachedOverview != null) {
        log('[DossierBloc] Overview déjà en cache — ignoré');
        return;
      }
      await _loadOverview(
        session:        session,
        cache:          cache,
        cachedOverview: null,
        emit:           emit,
      );
      return;
    }

    // ── Autres sections : lire cache ou fallback individuel ────────
    if (cache.containsKey(event.section)) {
      log('[DossierBloc] Cache hit: ${event.section.label}');
      emit(DossierSectionLoaded(
        session:        session,
        currentSection: event.section,
        sectionData:    cache[event.section]!,
        overviewData:   cachedOverview,
        cache:          cache,
      ));
      return;
    }

    // Fallback individuel (seulement si overview a été chargé
    // mais ne contenait pas cette section)
    if (cachedOverview != null) {
      await _loadSection(
        session:        session,
        section:        event.section,
        cache:          cache,
        cachedOverview: cachedOverview,
        emit:           emit,
      );
    }
  }

  // ════════════════════════════════════════════════════════════════
  // Fermeture manuelle
  // ════════════════════════════════════════════════════════════════
  void _onSessionClosed(DossierSessionClosed _, Emitter<DossierState> emit) {
    log('[DossierBloc] Session fermée');
    _cancelTimers();
    _overviewInFlight = false;
    emit(const DossierNoSession());
  }

  // ════════════════════════════════════════════════════════════════
  // Expiration
  // ════════════════════════════════════════════════════════════════
  void _onSessionExpired(DossierSessionExpired _, Emitter<DossierState> emit) {
    log('[DossierBloc] Session expirée (30 min)');
    _cancelTimers();
    _overviewInFlight = false;
    emit(const DossierSessionExpiredState());
    Future.delayed(const Duration(seconds: 3), () {
      if (!isClosed) add(DossierSessionClosed());
    });
  }

  // ════════════════════════════════════════════════════════════════
  // Tick countdown
  // ════════════════════════════════════════════════════════════════
  void _onTick(DossierTickRequested _, Emitter<DossierState> emit) {
    final current = state;
    if (current is DossierSectionLoaded) {
      if (current.session.isExpired) { add(DossierSessionExpired()); return; }
      emit(current.copyWithSession(current.session));
    } else if (current is DossierLoadingSection && current.session.isExpired) {
      add(DossierSessionExpired());
    }
  }

  // ════════════════════════════════════════════════════════════════
  // Charger overview (1 appel → toutes les données)
  // ════════════════════════════════════════════════════════════════
  Future<void> _loadOverview({
    required PatientSession                      session,
    required Map<DossierSection, List<dynamic>>  cache,
    required PatientOverviewData?                cachedOverview,
    required Emitter<DossierState>               emit,
  }) async {
    _overviewInFlight = true;

    emit(DossierLoadingSection(
      session:      session,
      section:      DossierSection.overview,
      overviewData: cachedOverview,
      cache:        cache,
    ));
    log('[DossierBloc] ⬇ Overview — patient ${session.patientId}');

    try {
      final raw = await _datasource.loadOverviewRaw(
        patientId: session.patientId,
        sessionId: session.sessionId,
      );

      final overviewData = PatientOverviewData.fromJson(raw);

      log('[DossierBloc] ✅ Overview: '
          '${overviewData.allergies.length} allergies, '
          '${overviewData.activePrescriptions.length} prescriptions, '
          '${overviewData.latestVitals.length} constantes');

      // ── Pré-peupler le cache depuis l'overview ─────────────────
      // RÈGLE : ne jamais écraser une section déjà chargée
      final preCache = Map<DossierSection, List<dynamic>>.from(cache);

      void tryCache(DossierSection section, String key) {
        if (preCache.containsKey(section)) return; // ← ne jamais écraser
        if (raw.containsKey(key) && raw[key] is List) {
          final list = raw[key] as List;
          preCache[section] = list;
          log('[DossierBloc] Pré-cache ${section.label}: ${list.length} éléments');
        }
      }

      tryCache(DossierSection.allergies,      'allergies');
      tryCache(DossierSection.prescriptions,  'prescriptions');
      tryCache(DossierSection.medicalRecords, 'medical_records');
      tryCache(DossierSection.vaccinations,   'vaccinations');
      tryCache(DossierSection.labs,           'labs');
      tryCache(DossierSection.imaging,        'imaging');
      tryCache(DossierSection.timeline,       'timeline');

      // ── Vitals : essai 'vitals' puis fallback 'latestVitals' ─────
      if (!preCache.containsKey(DossierSection.vitals)) {
        final vitalsRaw = raw['vitals'];
        if (vitalsRaw is List && (vitalsRaw).isNotEmpty) {
          preCache[DossierSection.vitals] = vitalsRaw;
          log('[DossierBloc] Pré-cache Constantes: ${vitalsRaw.length} éléments');
        } else {
          // Fallback sur latestVitals si vitals est vide
          final latestVitals = raw['latestVitals'];
          if (latestVitals is List && (latestVitals).isNotEmpty) {
            preCache[DossierSection.vitals] = latestVitals;
            log('[DossierBloc] Pré-cache Constantes (fallback latestVitals): '
                '${(latestVitals).length} éléments');
          } else {
            preCache[DossierSection.vitals] = [];
            log('[DossierBloc] Pré-cache Constantes: 0 éléments (aucune donnée)');
          }
        }
      }

      _overviewInFlight = false;

      emit(DossierSectionLoaded(
        session:        session,
        currentSection: DossierSection.overview,
        sectionData:    const [],
        overviewData:   overviewData,
        cache:          preCache,
      ));

    } catch (e) {
      log('[DossierBloc] ❌ Erreur overview: $e');
      _overviewInFlight = false;
      emit(DossierSectionError(
        session:      session,
        section:      DossierSection.overview,
        message:      'Impossible de charger le dossier médical.',
        overviewData: cachedOverview,
        cache:        cache,
      ));
    }
  }

  // ════════════════════════════════════════════════════════════════
  // Fallback : charger une section individuelle (retry uniquement)
  // ════════════════════════════════════════════════════════════════
  Future<void> _loadSection({
    required PatientSession                      session,
    required DossierSection                      section,
    required Map<DossierSection, List<dynamic>>  cache,
    required PatientOverviewData?                cachedOverview,
    required Emitter<DossierState>               emit,
  }) async {
    emit(DossierLoadingSection(
      session:      session,
      section:      section,
      overviewData: cachedOverview,
      cache:        cache,
    ));
    log('[DossierBloc] ⬇ Fallback ${section.label}');

    try {
      final data = await _datasource.loadSection(
        patientId:  session.patientId,
        sessionId:  session.sessionId,
        sectionKey: section.apiKey,
      );
      log('[DossierBloc] ✅ ${section.label}: ${data.length} élément(s)');
      final updated = Map<DossierSection, List<dynamic>>.from(cache)
        ..[section] = data;
      emit(DossierSectionLoaded(
        session:        session,
        currentSection: section,
        sectionData:    data,
        overviewData:   cachedOverview,
        cache:          updated,
      ));
    } catch (e) {
      log('[DossierBloc] ❌ Erreur ${section.label}: $e');
      emit(DossierSectionError(
        session:      session,
        section:      section,
        message:      'Impossible de charger ${section.label}.',
        overviewData: cachedOverview,
        cache:        cache,
      ));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────
  Map<DossierSection, List<dynamic>> _extractCache(DossierState state) {
    return switch (state) {
      DossierSectionLoaded() => Map.from(state.cache),
      DossierSectionError()  => Map.from(state.cache),
      DossierLoadingSection()=> Map.from(state.cache),
      _                      => {},
    };
  }

  void _cancelTimers() {
    _expiryTimer?.cancel(); _expiryTimer = null;
    _tickTimer?.cancel();   _tickTimer   = null;
  }

  @override
  Future<void> close() {
    _cancelTimers();
    return super.close();
  }
}