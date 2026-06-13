import 'dart:developer';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/messaging_models.dart';

class MessagingDatasource {
  const MessagingDatasource();

  Future<List<ConversationItem>> getConversations() async {
    log('[MessagingDatasource] Chargement conversations...');
    final data = await ApiClient.get(ApiEndpoints.getConversations);
    final list = data['conversations'] as List? ?? [];
    final result = list
        .map((e) => ConversationItem.fromJson(e as Map<String, dynamic>))
        .toList();
    log('[MessagingDatasource] ${result.length} conversation(s)');
    return result;
  }

  Future<List<MessageItem>> getMessages(int conversationId) async {
    log('[MessagingDatasource] Messages: conversation $conversationId');
    final data = await ApiClient.get(
      ApiEndpoints.getMessages,
      queryParams: {'conversationId': conversationId.toString()},
    );
    final list = data['messages'] as List? ?? [];
    return list
        .map((e) => MessageItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MessageItem> sendMessage({
    required int conversationId,
    required String content,
  }) async {
    log('[MessagingDatasource] Envoi message → conv $conversationId');
    final data = await ApiClient.post(ApiEndpoints.sendMessage, {
      'conversationId': conversationId,
      'content': content,
    });
    try {
      return MessageItem.fromJson(data['message'] as Map<String, dynamic>);
    } catch (e) {
      log('[MessagingDatasource] Erreur parsing message: $e');
      rethrow;
    }
  }
}
