// lib/features/dashboard/presentation/bloc/dashboard_bloc.dart

import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasource/dashboard_datasource.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardDatasource _datasource;

  DashboardBloc(this._datasource) : super(DashboardInitial()) {
    on<DashboardLoadRequested>   (_onLoad);
    on<DashboardRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final data = await _datasource.load();
      log('[DashboardBloc] Données chargées — '
          '${data.rdvDuJour.length} RDV, '
          '${data.criticalAlerts.length} alertes');
      emit(DashboardLoaded(data));
    } catch (e) {
      log('[DashboardBloc] Erreur: $e');
      emit(const DashboardError(
        'Impossible de charger le dashboard. Vérifiez votre connexion.'));
    }
  }

  Future<void> _onRefresh(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    // Garder le state actuel visible pendant le refresh
    try {
      final data = await _datasource.load();
      emit(DashboardLoaded(data));
      log('[DashboardBloc] Rafraîchi');
    } catch (e) {
      log('[DashboardBloc] Refresh erreur: $e');
      // Ne pas émettre d'erreur — garder les données actuelles
    }
  }
}