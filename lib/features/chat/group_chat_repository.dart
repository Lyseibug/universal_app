import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/group_chat_models.dart';
import '../../providers/service_providers.dart';

class GroupChatRepository {
  final ApiClient _api;

  GroupChatRepository({required ApiClient api}) : _api = api;

  Future<List<ChatGroupSummary>> getMyGroups() async {
    final dynamic data = await _api.call('group_chat.get_my_groups');
    if (data == null || data is! List) return [];
    return data.map((e) => ChatGroupSummary.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<ChatGroupMessage>> getGroupMessages(String group, {int limit = 30, String? before}) async {
    final dynamic data = await _api.call('group_chat.get_group_messages', body: {
      'group': group,
      'limit': limit,
      if (before != null) 'before': before,
    });
    if (data == null || data is! List) return [];
    return data.map((e) => ChatGroupMessage.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<ChatGroupMessage> sendGroupMessage(String group, String message) async {
    final dynamic data = await _api.call('group_chat.send_group_message', body: {
      'group': group,
      'message': message,
    });
    return ChatGroupMessage.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> markGroupRead(String group) async {
    await _api.call('group_chat.mark_group_read', body: {'group': group});
  }
}

final groupChatRepositoryProvider = Provider<GroupChatRepository>((ref) {
  return GroupChatRepository(api: ref.watch(apiClientProvider));
});
