import 'package:equatable/equatable.dart';

abstract class PatientSearchEvent extends Equatable {
  const PatientSearchEvent();
  @override List<Object?> get props => [];
}

class PatientSearchLoadRequested extends PatientSearchEvent {}

class PatientSearchQueryChanged extends PatientSearchEvent {
  final String query;
  const PatientSearchQueryChanged(this.query);
  @override List<Object> get props => [query];
}

class PatientSearchRefreshRequested extends PatientSearchEvent {}
