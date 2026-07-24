import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/direct_chat_models.dart';
import '../../providers/service_providers.dart';

class DirectChatRepository {
  final ApiClient _api;

  DirectChatRepository({required ApiClient api}) : _api = api;

  Future<List<PdtContact>> listContacts({String? search}) async {
    final dynamic data = await _api.call('direct_chat.list_contacts', body: {
      if (search != null && search.isNotEmpty) 'search': search,
    });
    if (data == null || data is! List) return [];
    return data.map((e) => PdtContact.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<DirectConversationSummary>> getConversations() async {
    final dynamic data = await _api.call('direct_chat.get_conversations');
    if (data == null || data is! List) return [];
    return data.map((e) => DirectConversationSummary.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<DirectMessage>> getMessages(String withUser, {int limit = 30, String? before}) async {
    final dynamic data = await _api.call('direct_chat.get_messages', body: {
      'with_user': withUser,
      'limit': limit,
      if (before != null) 'before': before,
    });
    if (data == null || data is! List) return [];
    return data.map((e) => DirectMessage.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<DirectMessage> sendMessage(String toUser, String message) async {
    final dynamic data = await _api.call('direct_chat.send_message', body: {
      'to_user': toUser,
      'message': message,
    });
    return DirectMessage.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> markRead(String withUser) async {
    await _api.call('direct_chat.mark_read', body: {'with_user': withUser});
  }
}

final directChatRepositoryProvider = Provider<DirectChatRepository>((ref) {
  return DirectChatRepository(api: ref.watch(apiClientProvider));
});
