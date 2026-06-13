import 'package:equatable/equatable.dart';

import '../../data/models/messaging_models.dart';

abstract class MessagingEvent extends Equatable {
  const MessagingEvent();
  @override List<Object?> get props => [];
}

class MessagingLoadConversations extends MessagingEvent {}

class MessagingSelectConversation extends MessagingEvent {
  final int conversationId;
  const MessagingSelectConversation(this.conversationId);
  @override List<Object> get props => [conversationId];
}

class MessagingLoadMessages extends MessagingEvent {
  final int conversationId;
  const MessagingLoadMessages(this.conversationId);
  @override List<Object> get props => [conversationId];
}

class MessagingSendMessage extends MessagingEvent {
  final int    conversationId;
  final String content;
  const MessagingSendMessage({required this.conversationId, required this.content});
  @override List<Object> get props => [conversationId, content];
}

class MessagingNewMessageReceived extends MessagingEvent {
  final int         conversationId;
  final MessageItem message;
  const MessagingNewMessageReceived({
    required this.conversationId, required this.message});
  @override List<Object> get props => [conversationId, message.id];
}

class MessagingRefresh extends MessagingEvent {}