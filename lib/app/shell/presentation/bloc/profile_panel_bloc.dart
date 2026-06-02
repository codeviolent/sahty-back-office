import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasource/profile_panel_datasource.dart';
import 'profile_panel_event.dart';
import 'profile_panel_state.dart';

class ProfilePanelBloc
    extends Bloc<ProfilePanelEvent, ProfilePanelState> {
  final ProfilePanelDatasource _datasource;

  ProfilePanelBloc(this._datasource) : super(ProfilePanelInitial()) {
    on<ProfilePanelLoadRequested>   (_onLoad);
    on<ProfilePanelRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    ProfilePanelLoadRequested event,
    Emitter<ProfilePanelState> emit,
  ) async {
    emit(ProfilePanelLoading());
    try {
      final profile = await _datasource.loadMyProfile();
      log('[ProfilePanelBloc] Profil chargé: ${profile.role} — ${profile.displayName}');
      emit(ProfilePanelLoaded(profile));
    } catch (e) {
      log('[ProfilePanelBloc] Erreur: $e');
      emit(const ProfilePanelError('Impossible de charger le profil'));
    }
  }

  Future<void> _onRefresh(
    ProfilePanelRefreshRequested event,
    Emitter<ProfilePanelState> emit,
  ) async {
    try {
      final profile = await _datasource.loadMyProfile();
      emit(ProfilePanelLoaded(profile));
    } catch (e) {
      log('[ProfilePanelBloc] Refresh erreur: $e');
    }
  }
}