import 'package:equatable/equatable.dart';
import '../../data/models/messaging_models.dart';

class MessagingState extends Equatable {
  final List<ConversationItem> conversations;
  final int?                   selectedConversationId;
  final List<MessageItem>      messages;
  final bool                   isLoadingConversations;
  final bool                   isLoadingMessages;
  final bool                   isSending;
  final String?                error;
  final String?                sendError;

  const MessagingState({
    this.conversations            = const [],
    this.selectedConversationId,
    this.messages                 = const [],
    this.isLoadingConversations   = false,
    this.isLoadingMessages        = false,
    this.isSending                = false,
    this.error,
    this.sendError,
  });

  ConversationItem? get selectedConversation => selectedConversationId == null
      ? null
      : conversations.where((c) => c.id == selectedConversationId)
          .cast<ConversationItem?>().firstOrNull;

  int get totalUnread =>
      conversations.fold(0, (sum, c) => sum + c.unreadByDoctor);

  MessagingState copyWith({
    List<ConversationItem>? conversations,
    int?                    selectedConversationId,
    List<MessageItem>?      messages,
    bool?                   isLoadingConversations,
    bool?                   isLoadingMessages,
    bool?                   isSending,
    String?                 error,
    String?                 sendError,
    bool                    clearError     = false,
    bool                    clearSendError = false,
    bool                    clearSelected  = false,
  }) => MessagingState(
    conversations:          conversations          ?? this.conversations,
    selectedConversationId: clearSelected
        ? null
        : selectedConversationId ?? this.selectedConversationId,
    messages:               messages               ?? this.messages,
    isLoadingConversations: isLoadingConversations ?? this.isLoadingConversations,
    isLoadingMessages:      isLoadingMessages      ?? this.isLoadingMessages,
    isSending:              isSending              ?? this.isSending,
    error:                  clearError     ? null : (error     ?? this.error),
    sendError:              clearSendError ? null : (sendError ?? this.sendError),
  );

  @override
  List<Object?> get props => [
    conversations.length,
    selectedConversationId,
    messages.length,
    isLoadingConversations,
    isLoadingMessages,
    isSending,
    error,
    sendError,
  ];
}