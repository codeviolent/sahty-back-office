import 'package:equatable/equatable.dart';

abstract class ProfilePanelEvent extends Equatable {
  const ProfilePanelEvent();
  @override List<Object?> get props => [];
}

class ProfilePanelLoadRequested    extends ProfilePanelEvent {}
class ProfilePanelRefreshRequested extends ProfilePanelEvent {}