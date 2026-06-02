import 'package:equatable/equatable.dart';
import '../../data/models/profile_models.dart';

abstract class ProfilePanelState extends Equatable {
  const ProfilePanelState();
  @override List<Object?> get props => [];
}

class ProfilePanelInitial extends ProfilePanelState {}
class ProfilePanelLoading extends ProfilePanelState {}

class ProfilePanelLoaded extends ProfilePanelState {
  final UserProfile profile;
  const ProfilePanelLoaded(this.profile);
  @override List<Object?> get props => [profile];
}

class ProfilePanelError extends ProfilePanelState {
  final String message;
  const ProfilePanelError(this.message);
  @override List<Object?> get props => [message];
}