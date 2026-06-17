import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String subject,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'email_content') String? content,
    required String type, // 'Alert', 'Mention', 'Share', 'Assignment'
    // ignore: invalid_annotation_target
    @JsonKey(name: 'read', defaultValue: false) required bool read,
    required DateTime creation,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    if (map['read'] is int) {
      map['read'] = map['read'] == 1;
    } else if (map['read'] is String) {
      map['read'] = map['read'] == '1' || map['read'] == 'true';
    }

    if (map['subject'] is String) {
      map['subject'] = _stripHtml(map['subject'] as String);
    }
    if (map['email_content'] is String) {
      map['email_content'] = _stripHtml(map['email_content'] as String);
    }

    return _$AppNotificationFromJson(map);
  }

  static String _stripHtml(String htmlString) {
    if (htmlString.isEmpty) return '';
    String result = htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
    result = result
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
    return result.trim();
  }
}
