import 'package:equatable/equatable.dart';
import '../../../data/models/appointment_item.dart';

abstract class AgendaState extends Equatable {
  const AgendaState();
  @override List<Object?> get props => [];
}

class AgendaInitial extends AgendaState {}
class AgendaLoading extends AgendaState {}

class AgendaLoaded extends AgendaState {
  final ListRdv data;
  const AgendaLoaded(this.data);
  @override List<Object> get props => [data];
}

class AgendaError extends AgendaState {
  final String message;
  const AgendaError(this.message);
  @override List<Object> get props => [message];
}