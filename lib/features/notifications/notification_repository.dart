import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/app_notification.dart';
import '../../providers/service_providers.dart';

class NotificationRepository {
  final ApiClient _api;

  NotificationRepository({required ApiClient api}) : _api = api;

  /// Fetch notifications for current user
  Future<List<AppNotification>> getNotifications({int limit = 20, int start = 0}) async {
    final dynamic response = await _api.call('notifications.get_notifications', body: {
      'limit': limit,
      'start': start,
    });
    if (response == null || response is! List) {
      return [];
    }
    final List<dynamic> data = response;
    return data.map((item) {
      final map = Map<String, dynamic>.from(item);
      // Map 'name' from ERPNext to 'id' for the app model
      map['id'] = map['name'] ?? '';
      // Parse creation time correctly
      if (map['creation'] != null && map['creation'] is String) {
        // Ensure parsing works
        final dateStr = map['creation'] as String;
        // Parse "YYYY-MM-DD HH:MM:SS.mmmmmm" or ISO format
        map['creation'] = DateTime.parse(dateStr).toIso8601String();
      }
      return AppNotification.fromJson(map);
    }).toList();
  }

  /// Get number of unread notifications
  Future<int> getUnreadCount() async {
    final dynamic count = await _api.call('notifications.get_unread_count');
    return int.tryParse(count.toString()) ?? 0;
  }

  /// Mark specific or all notifications as read
  Future<void> markRead({String? id, bool markAll = false}) async {
    final Map<String, dynamic> body = {
      'mark_all': markAll,
    };
    if (id != null) {
      body['notification_id'] = id;
    }
    await _api.call('notifications.mark_read', body: body);
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(api: ref.watch(apiClientProvider));
});
