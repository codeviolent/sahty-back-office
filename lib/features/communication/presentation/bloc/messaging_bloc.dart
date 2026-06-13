import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/messaging_datasource.dart';
import '../../data/models/messaging_models.dart';
import 'messaging_event.dart';
import 'messaging_state.dart';

class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final MessagingDatasource _datasource;
  RealtimeChannel? _realtimeChannel;

  // ← Constructeur SANS paramètre supabaseClient
  // Supabase.instance est accessible après await Supabase.initialize() dans main.dart
  MessagingBloc(this._datasource) : super(const MessagingState()) {
    on<MessagingLoadConversations>(_onLoadConversations);
    on<MessagingSelectConversation>(_onSelectConversation);
    on<MessagingLoadMessages>(_onLoadMessages);
    on<MessagingSendMessage>(_onSendMessage);
    on<MessagingNewMessageReceived>(_onNewMessageReceived);
    on<MessagingRefresh>(_onRefresh);
  }

  Future<void> _onLoadConversations(
    MessagingLoadConversations _,
    Emitter<MessagingState> emit,
  ) async {
    emit(state.copyWith(isLoadingConversations: true, clearError: true));
    try {
      final conversations = await _datasource.getConversations();
      log('[MessagingBloc] ${conversations.length} conversations chargées');
      emit(
        state.copyWith(
          conversations: conversations,
          isLoadingConversations: false,
        ),
      );
      if (conversations.isNotEmpty && state.selectedConversationId == null) {
        add(MessagingSelectConversation(conversations.first.id));
      }
    } catch (e) {
      log('[MessagingBloc] ❌ Erreur conversations: $e');
      emit(
        state.copyWith(
          isLoadingConversations: false,
          error: 'Impossible de charger les conversations.',
        ),
      );
    }
  }

  Future<void> _onSelectConversation(
    MessagingSelectConversation event,
    Emitter<MessagingState> emit,
  ) async {
    if (state.selectedConversationId == event.conversationId) return;
    emit(
      state.copyWith(
        selectedConversationId: event.conversationId,
        messages: const [],
        isLoadingMessages: true,
      ),
    );
    _subscribeToRealtime(event.conversationId);
    add(MessagingLoadMessages(event.conversationId));
  }

  Future<void> _onLoadMessages(
    MessagingLoadMessages event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      final messages = await _datasource.getMessages(event.conversationId);
      log('[MessagingBloc] ${messages.length} messages chargés');
      final updatedConversations = state.conversations.map((c) {
        if (c.id == event.conversationId) {
          return ConversationItem(
            id: c.id,
            status: c.status,
            lastMessagePreview: c.lastMessagePreview,
            lastMessageAt: c.lastMessageAt,
            unreadByDoctor: 0,
            patient: c.patient,
          );
        }
        return c;
      }).toList();
      emit(
        state.copyWith(
          messages: messages,
          isLoadingMessages: false,
          conversations: updatedConversations,
        ),
      );
    } catch (e) {
      log('[MessagingBloc] ❌ Erreur messages: $e');
      emit(
        state.copyWith(
          isLoadingMessages: false,
          error: 'Impossible de charger les messages.',
        ),
      );
    }
  }

  Future<void> _onSendMessage(
    MessagingSendMessage event,
    Emitter<MessagingState> emit,
  ) async {
    emit(state.copyWith(isSending: true, clearSendError: true));
    try {
      final sent = await _datasource.sendMessage(
        conversationId: event.conversationId,
        content: event.content,
      );
      log('[MessagingBloc] ✅ Message envoyé: ${sent.id}');
      final updatedMessages = [...state.messages, sent];
      final updatedConversations = state.conversations.map((c) {
        if (c.id == event.conversationId) {
          return ConversationItem(
            id: c.id,
            status: c.status,
            lastMessagePreview: event.content,
            lastMessageAt: sent.createdAt,
            unreadByDoctor: c.unreadByDoctor,
            patient: c.patient,
          );
        }
        return c;
      }).toList()..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      emit(
        state.copyWith(
          messages: updatedMessages,
          conversations: updatedConversations,
          isSending: false,
        ),
      );
    } catch (e) {
      log('[MessagingBloc] ❌ Erreur envoi: $e');
      emit(
        state.copyWith(
          isSending: false,
          sendError: 'Impossible d\'envoyer le message.',
        ),
      );
    }
  }

  void _onNewMessageReceived(
    MessagingNewMessageReceived event,
    Emitter<MessagingState> emit,
  ) {
    if (state.messages.any((m) => m.id == event.message.id)) return;
    if (state.selectedConversationId == event.conversationId) {
      emit(state.copyWith(messages: [...state.messages, event.message]));
    }
    final updatedConversations = state.conversations.map((c) {
      if (c.id == event.conversationId) {
        final isSelected = state.selectedConversationId == event.conversationId;
        return ConversationItem(
          id: c.id,
          status: c.status,
          lastMessagePreview: event.message.content,
          lastMessageAt: event.message.createdAt,
          unreadByDoctor: isSelected ? 0 : c.unreadByDoctor + 1,
          patient: c.patient,
        );
      }
      return c;
    }).toList()..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    emit(state.copyWith(conversations: updatedConversations));
  }

  Future<void> _onRefresh(
    MessagingRefresh _,
    Emitter<MessagingState> emit,
  ) async {
    add(MessagingLoadConversations());
  }

  // ── Realtime — lazy, appelé seulement après sélection conversation ─
  void _subscribeToRealtime(int conversationId) {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;

    try {
      // Accès LAZY : appelé seulement quand le médecin sélectionne une conv
      // À ce moment, Supabase.initialize() a déjà été appelé dans main.dart
      final supabase = Supabase.instance.client;

      _realtimeChannel = supabase
          .channel('messages:conv:$conversationId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: conversationId,
            ),
            callback: (PostgresChangePayload payload) {
              log('[MessagingBloc] 🔔 Nouveau message Realtime');
              try {
                final rec = payload.newRecord;
                if (rec.isEmpty) return;
                final msg = MessageItem(
                  id: (rec['id'] as num).toInt(),
                  senderId: rec['sender_uuid'] as String? ?? '',
                  senderRole: rec['sender_role'] as String? ?? 'patient',
                  content: rec['content'] as String? ?? '',
                  isRead: rec['is_read'] as bool? ?? false,
                  createdAt: DateTime.parse(
                    rec['created_at'] as String? ??
                        DateTime.now().toIso8601String(),
                  ),
                );
                if (!isClosed) {
                  add(
                    MessagingNewMessageReceived(
                      conversationId: conversationId,
                      message: msg,
                    ),
                  );
                }
              } catch (e) {
                log('[MessagingBloc] ❌ Parse Realtime: $e');
              }
            },
          )
          .subscribe((status, [error]) {
            log(
              '[MessagingBloc] Realtime: $status'
              '${error != null ? " — $error" : ""}',
            );
          });
    } catch (e) {
      log('[MessagingBloc] ❌ Realtime non disponible: $e');
    }
  }

  @override
  Future<void> close() async {
    _realtimeChannel?.unsubscribe();
    return super.close();
  }
}
