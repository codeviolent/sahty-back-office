import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasource/patient_search_datasource.dart';
import '../../data/models/patient_search_models.dart';
import 'patient_search_event.dart';
import 'patient_search_state.dart';

class PatientSearchBloc extends Bloc<PatientSearchEvent, PatientSearchBlocState> {
  final PatientSearchDatasource _datasource;
  Timer? _debounce;

  PatientSearchBloc(this._datasource) : super(PatientSearchInitial()) {
    on<PatientSearchLoadRequested>   (_onLoad);
    on<PatientSearchQueryChanged>    (_onQueryChanged);
    on<PatientSearchRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    PatientSearchLoadRequested event,
    Emitter<PatientSearchBlocState> emit,
  ) async {
    emit(PatientSearchLoading());
    try {
      final result = await _datasource.getPatients();
      log('[PatientSearchBloc] ${result.patients.length} patients chargés');
      emit(PatientSearchLoaded(
        allPatients: result.patients,
        displayed:   result.patients,
        query:       '',
        total:       result.total,
      ));
    } catch (e) {
      log('[PatientSearchBloc] Erreur: $e');
      emit(PatientSearchError(
        'Impossible de charger les patients. Vérifiez votre connexion.'));
    }
  }

  void _onQueryChanged(
    PatientSearchQueryChanged event,
    Emitter<PatientSearchBlocState> emit,
  ) {
    _debounce?.cancel();

    final current = state;
    if (current is! PatientSearchLoaded) return;

    final query = event.query.trim().toLowerCase();

    // Filtre côté client immédiat sur les données déjà chargées
    final filtered = query.isEmpty
        ? current.allPatients
        : current.allPatients.where((p) {
            return p.fullName.toLowerCase().contains(query)  ||
                   p.nniMasked.contains(query)               ||
                   (p.lastReason.toLowerCase().contains(query));
          }).toList();

    emit(PatientSearchLoaded(
      allPatients: current.allPatients,
      displayed:   filtered,
      query:       event.query,
      total:       current.total,
    ));

    // Debounce 600ms → requête API si query longue (> 2 chars)
    if (query.length > 2) {
      _debounce = Timer(const Duration(milliseconds: 600), () {
        _fetchFromApi(query, emit, current.allPatients);
      });
    }
  }

  Future<void> _fetchFromApi(
    String query,
    Emitter<PatientSearchBlocState> emit,
    List<PatientSearchResult> currentAll,
  ) async {
    try {
      final result = await _datasource.getPatients(search: query);
      log('[PatientSearchBloc] ${result.patients.length} patients trouvés pour la recherche: "$query"');
      emit(PatientSearchLoaded(
        allPatients: currentAll,  // garder la liste complète
        displayed:   result.patients,
        query:       query,
        total:       result.total,
      ));
    } catch (_) {
      // Silencieux — garder les résultats filtrés localement
    }
  }

  Future<void> _onRefresh(
    PatientSearchRefreshRequested event,
    Emitter<PatientSearchBlocState> emit,
  ) async {
    try {
      final result = await _datasource.getPatients();
      emit(PatientSearchLoaded(
        allPatients: result.patients,
        displayed:   result.patients,
        query:       '',
        total:       result.total,
      ));
    } catch (e) {
      log('[PatientSearchBloc] Refresh erreur: $e');
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}