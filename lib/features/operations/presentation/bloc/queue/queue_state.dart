import 'package:equatable/equatable.dart';

import '../../../data/models/queue_models.dart';

abstract class QueueState extends Equatable {
  const QueueState();
  @override List<Object?> get props => [];
}

class QueueInitial extends QueueState {}
class QueueLoading extends QueueState {}

class QueueLoaded extends QueueState {
  final List<QueueItem> items;
  const QueueLoaded(this.items);

  // Partitionner par priorité courante (recalculée localement)
  List<QueueItem> get highPriority =>
      items.where((i) => i.currentPriority == QueuePriority.high).toList();
  List<QueueItem> get mediumPriority =>
      items.where((i) => i.currentPriority == QueuePriority.medium).toList();
  List<QueueItem> get lowPriority =>
      items.where((i) => i.currentPriority == QueuePriority.low).toList();

  @override List<Object> get props => [items];
}

class QueueError extends QueueState {
  final String message;
  const QueueError(this.message);
  @override List<Object> get props => [message];
}