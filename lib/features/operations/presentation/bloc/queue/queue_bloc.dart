import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasource/QueueDatasource/queue_datasource.dart';
import 'queue_event.dart';
import 'queue_state.dart';

class QueueBloc extends Bloc<QueueEvent, QueueState> {
  final QueueDatasource _datasource;
  Timer? _ticker;

  QueueBloc(this._datasource) : super(QueueInitial()) {
    on<QueueLoadRequested>   (_onLoad);
    on<QueueRefreshRequested>(_onRefresh);
    on<QueueTickRequested>   (_onTick);
  }

  Future<void> _onLoad(
    QueueLoadRequested event,
    Emitter<QueueState> emit,
  ) async {
    emit(QueueLoading());
    try {
      final items = await _datasource.getQueue();
      log('[QueueBloc] ${items.length} patients en file');
      emit(QueueLoaded(items));
      _startTicker();
    } catch (e) {
      log('[QueueBloc] Erreur: $e');
      emit(const QueueError('Impossible de charger la file d\'attente'));
    }
  }

  Future<void> _onRefresh(
    QueueRefreshRequested event,
    Emitter<QueueState> emit,
  ) async {
    try {
      final items = await _datasource.getQueue();
      emit(QueueLoaded(items));
    } catch (e) {
      log('[QueueBloc] Refresh erreur: $e');
    }
  }

  // ── Timer toutes les 60s pour recalculer les priorités ────────
  // Ne refait PAS d'appel API — recalcule localement depuis createdAt
  void _onTick(QueueTickRequested event, Emitter<QueueState> emit) {
    if (state is QueueLoaded) {
      // Même liste, les getters recalculent automatiquement
      emit(QueueLoaded((state as QueueLoaded).items));
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => add(QueueTickRequested()),
    );
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}