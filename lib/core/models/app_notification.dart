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
    // ignore: invalid_annotation_target
    @JsonKey(name: 'document_type') String? documentType,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'document_name') String? documentName,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(_preprocessJson(json));

  static Map<String, dynamic> _preprocessJson(Map<String, dynamic> json) {
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

    return map;
  }

  static String _stripHtml(String htmlString) {
    if (htmlString.isEmpty) return '';

    String result = htmlString;

    // Step 1: Remove complete HTML tags using character-level parser
    // (handles quoted attributes containing '>' characters)
    final buffer = StringBuffer();
    bool inTag = false;
    bool inSingleQuote = false;
    bool inDoubleQuote = false;

    for (int i = 0; i < result.length; i++) {
      final char = result[i];
      if (inTag) {
        if (inDoubleQuote) {
          if (char == '"') inDoubleQuote = false;
        } else if (inSingleQuote) {
          if (char == "'") inSingleQuote = false;
        } else if (char == '"') {
          inDoubleQuote = true;
        } else if (char == "'") {
          inSingleQuote = true;
        } else if (char == '>') {
          inTag = false;
        }
      } else if (char == '<') {
        inTag = true;
        inSingleQuote = false;
        inDoubleQuote = false;
      } else {
        buffer.write(char);
      }
    }
    result = buffer.toString();

    // Step 2: Decode HTML entities
    result = result
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&nbsp;', ' ');

    // Step 3: Remove data-* attributes and their values that leaked outside tags
    result = result.replaceAll(RegExp(r'data-[\w-]+=\s*"[^"]*"'), '');
    result = result.replaceAll(RegExp(r"data-[\w-]+=\s*'[^']*'"), '');

    // Step 4: Remove class="..." href="..." style="..." and similar leaked attributes
    result = result.replaceAll(
      RegExp(
        r'(class|href|style|target|rel|id|name|title|src|alt)\s*=\s*"[^"]*"',
        caseSensitive: false,
      ),
      '',
    );
    result = result.replaceAll(
      RegExp(
        r"(class|href|style|target|rel|id|name|title|src|alt)\s*=\s*'[^']*'",
        caseSensitive: false,
      ),
      '',
    );

    // Step 5: Remove stray "> or " > or '/> or > characters (with optional spaces)
    result = result.replaceAll(RegExp(r'"\s*>'), ' ');
    result = result.replaceAll(RegExp(r"'\s*>"), ' ');
    result = result.replaceAll(RegExp(r'\s*/>\s*'), ' ');
    result = result.replaceAll(
      RegExp(r'(?<!\w)>'),
      ' ',
    ); // lone > not part of a word

    // Step 6: Remove all remaining " characters (they are always HTML remnants in notification text)
    result = result.replaceAll('"', ' ');

    // Step 7: Remove @ prefix from mention names
    result = result.replaceAll(RegExp(r'@(?=\w)'), '');

    // Step 8: Collapse spaces before deduplication
    result = result.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    // Step 9: Remove duplicate name — split into words and find repeated sequence
    final words = result.split(' ');
    if (words.length >= 4) {
      // Try all possible phrase lengths from longest to shortest
      for (int phraseLen = words.length ~/ 2; phraseLen >= 2; phraseLen--) {
        bool found = false;
        for (int i = 0; i <= words.length - phraseLen * 2; i++) {
          final phrase1 = words.sublist(i, i + phraseLen).join(' ');
          final phrase2 = words
              .sublist(i + phraseLen, i + phraseLen * 2)
              .join(' ');
          if (phrase1 == phrase2) {
            // Remove the duplicate
            words.removeRange(i + phraseLen, i + phraseLen * 2);
            found = true;
            break;
          }
        }
        if (found) break;
      }
      result = words.join(' ');
    }

    return result.trim();
  }
}
