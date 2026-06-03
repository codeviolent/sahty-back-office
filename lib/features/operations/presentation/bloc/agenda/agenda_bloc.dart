// lib/features/agenda/presentation/bloc/agenda_bloc.dart

import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasource/AgendaDatasource/agenda_datasource.dart';
import 'agenda_event.dart';
import 'agenda_state.dart';

class AgendaBloc extends Bloc<AgendaEvent, AgendaState> {
  final AgendaDatasource _datasource;

  AgendaBloc(this._datasource) : super(AgendaInitial()) {
    on<AgendaLoadRequested>   (_onLoad);
    on<AgendaRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    AgendaLoadRequested event,
    Emitter<AgendaState> emit,
  ) async {
    emit(AgendaLoading());
    try {
      final data = await _datasource.load();
      log('[AgendaBloc] Données chargées — '
          '${data.rdvList.length} RDV, '
          '${data.rdvList} alertes');
      emit(AgendaLoaded(data));
    } catch (e) {
      log('[AgendaBloc] Erreur: $e');
      emit(const AgendaError(
        'Impossible de charger l\'agenda. Vérifiez votre connexion.'));
    }
  }

  Future<void> _onRefresh(
    AgendaRefreshRequested event,
    Emitter<AgendaState> emit,
  ) async {
    // Garder le state actuel visible pendant le refresh
    try {
      final data = await _datasource.load();
      emit(AgendaLoaded(data));
      log('[AgendaBloc] Rafraîchi');
    } catch (e) {
      log('[AgendaBloc] Refresh erreur: $e');
      // Ne pas émettre d'erreur — garder les données actuelles
    }
  }
}