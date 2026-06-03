import 'package:equatable/equatable.dart';

abstract class AgendaEvent extends Equatable {
  const AgendaEvent();
  @override List<Object?> get props => [];
}

class AgendaLoadRequested    extends AgendaEvent {}
class AgendaRefreshRequested extends AgendaEvent {}