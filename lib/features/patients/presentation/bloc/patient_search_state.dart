import 'package:equatable/equatable.dart';

import '../../data/models/patient_search_models.dart';

abstract class PatientSearchBlocState extends Equatable {
  const PatientSearchBlocState();
  @override List<Object?> get props => [];
}

class PatientSearchInitial extends PatientSearchBlocState {}
class PatientSearchLoading  extends PatientSearchBlocState {}

class PatientSearchLoaded extends PatientSearchBlocState {
  final List<PatientSearchResult> allPatients;
  final List<PatientSearchResult> displayed;
  final String query;
  final int    total;

  const PatientSearchLoaded({
    required this.allPatients,
    required this.displayed,
    required this.query,
    required this.total,
  });

  @override List<Object> get props =>
      [allPatients, displayed, query, total];
}

class PatientSearchError extends PatientSearchBlocState {
  final String message;
  const PatientSearchError(this.message);
  @override List<Object> get props => [message];
}