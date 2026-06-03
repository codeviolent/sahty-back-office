import 'package:equatable/equatable.dart';

abstract class QueueEvent extends Equatable {
  const QueueEvent();
  @override List<Object?> get props => [];
}

class QueueLoadRequested    extends QueueEvent {}
class QueueRefreshRequested extends QueueEvent {}
class QueueTickRequested    extends QueueEvent {} // Timer toutes les 60s